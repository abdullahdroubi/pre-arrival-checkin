package com.petrabooking.checkin.service;

import com.petrabooking.checkin.config.SupabaseConfig;
import com.petrabooking.checkin.model.Booking;
import com.petrabooking.checkin.model.Hotel;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

@Service
public class SupabaseService {

    @Autowired
    private SupabaseConfig supabaseConfig;

    private final RestTemplate restTemplate;

    public SupabaseService() {
        this.restTemplate = new RestTemplate();
    }

    // Server-side app should use service role key
    private HttpHeaders createServiceHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.set("apikey", supabaseConfig.getSupabaseServiceRoleKey());
        headers.set("Authorization", "Bearer " + supabaseConfig.getSupabaseServiceRoleKey());
        headers.setContentType(MediaType.APPLICATION_JSON);
        return headers;
    }

    // Accepts booking values like BK000039 or 39
    public Booking getBookingByReference(String bookingReference) {
        if (bookingReference == null || bookingReference.isBlank()) {
            return null;
        }

        String value = bookingReference.trim();
        System.out.println("[SUPABASE] getBookingByReference input=" + value);

        // 1) Try numeric ID extracted from BK format
        String digits = value.replaceAll("[^0-9]", "");
        if (!digits.isBlank()) {
            try {
                int id = Integer.parseInt(digits);
                Booking byId = getBookingById(id);
                if (byId != null) {
                    System.out.println("[SUPABASE] Booking found by id=" + id);
                    return byId;
                }
            } catch (NumberFormatException ignored) {
            }
        }

        // 2) Fallback by booking_reference if column exists
        String url = supabaseConfig.getSupabaseUrl() + "/rest/v1/bookings";
        UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(url)
                .queryParam("booking_reference", "eq." + value)
                .queryParam("select", "*");

        HttpEntity<String> entity = new HttpEntity<>(createServiceHeaders());

        try {
            System.out.println("[SUPABASE] Fallback URL: " + builder.toUriString());
            ResponseEntity<Booking[]> response = restTemplate.exchange(
                    builder.toUriString(),
                    HttpMethod.GET,
                    entity,
                    Booking[].class
            );

            Booking[] body = response.getBody();
            if (body != null && body.length > 0) {
                System.out.println("[SUPABASE] Booking found by booking_reference");
                return body[0];
            }
        } catch (Exception e) {
            // if booking_reference column doesn't exist, fallback will fail; that's fine
            System.out.println("[SUPABASE] Fallback by booking_reference failed: " + e.getMessage());
        }

        System.out.println("[SUPABASE] Booking not found for input=" + value);
        return null;
    }

    public Booking getBookingById(int bookingId) {
        String url = supabaseConfig.getSupabaseUrl() + "/rest/v1/bookings";

        UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(url)
                .queryParam("id", "eq." + bookingId)
                .queryParam("select", "*");

        HttpEntity<String> entity = new HttpEntity<>(createServiceHeaders());

        try {
            System.out.println("[SUPABASE] getBookingById URL: " + builder.toUriString());
            ResponseEntity<Booking[]> response = restTemplate.exchange(
                    builder.toUriString(),
                    HttpMethod.GET,
                    entity,
                    Booking[].class
            );

            Booking[] body = response.getBody();
            System.out.println("[SUPABASE] getBookingById rows=" + (body == null ? 0 : body.length));

            if (body != null && body.length > 0) {
                return body[0];
            }
        } catch (Exception e) {
            System.out.println("[SUPABASE] getBookingById failed: " + e.getMessage());
        }

        return null;
    }

    public Hotel getHotelById(Integer hotelId) {
        if (hotelId == null) {
            return null;
        }

        String url = supabaseConfig.getSupabaseUrl() + "/rest/v1/hotels";

        UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(url)
                .queryParam("id", "eq." + hotelId)
                .queryParam("select", "*");

        HttpEntity<String> entity = new HttpEntity<>(createServiceHeaders());

        try {
            ResponseEntity<Map[]> response = restTemplate.exchange(
                    builder.toUriString(),
                    HttpMethod.GET,
                    entity,
                    Map[].class
            );

            if (response.getBody() != null && response.getBody().length > 0) {
                Map<String, Object> hotelData = response.getBody()[0];
                Hotel hotel = new Hotel();

                Object idObj = hotelData.get("id");
                if (idObj instanceof Number) {
                    hotel.setId(((Number) idObj).intValue());
                }

                hotel.setName((String) hotelData.get("name"));
                hotel.setAddress((String) hotelData.get("address"));
                hotel.setCity((String) hotelData.get("city"));
                hotel.setCountry((String) hotelData.get("country"));

                Object imagesObj = hotelData.get("images");
                if (imagesObj instanceof List) {
                    hotel.setImages((List<String>) imagesObj);
                } else if (imagesObj instanceof String[]) {
                    hotel.setImages(Arrays.asList((String[]) imagesObj));
                }

                return hotel;
            }
        } catch (Exception e) {
            System.out.println("[SUPABASE] getHotelById failed: " + e.getMessage());
        }

        return null;
    }

    public void submitCheckIn(Map<String, Object> checkInData) {
        String url = supabaseConfig.getSupabaseUrl() + "/rest/v1/pre_checkin_submissions";
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(checkInData, createServiceHeaders());

        try {
            restTemplate.postForObject(url, entity, String.class);
        } catch (Exception e) {
            e.printStackTrace();
            throw new RuntimeException("Failed to submit check-in: " + e.getMessage());
        }
    }
}