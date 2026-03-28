package com.petrabooking.checkin.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.petrabooking.checkin.config.SupabaseConfig;
import com.petrabooking.checkin.model.Booking;
import com.petrabooking.checkin.model.Hotel;
import com.petrabooking.checkin.model.UpgradeRoomOption;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
public class SupabaseService {

    @Autowired
    private SupabaseConfig supabaseConfig;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public SupabaseService() {
        this.restTemplate = new RestTemplate();
    }

    private static final DateTimeFormatter ISO_DATE = DateTimeFormatter.ISO_LOCAL_DATE;

    private static String formatJod(double amount) {
        return String.format(Locale.US, "%,.2f JD", amount);
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

    /**
     * Rooms at {@code hotelId} free for the stay, excluding other guests' overlapping confirmed bookings.
     * The current booking is excluded from overlap so the guest's own room stays selectable.
     *
     * @param guestCurrentRoomId if set, that room is included even when status is not {@code available}
     *                           (guest already holds it for this stay).
     */
    public List<JsonNode> getAvailableRoomsForHotel(
            int hotelId,
            LocalDate checkIn,
            LocalDate checkOut,
            int excludeBookingId,
            Integer guestCurrentRoomId) {

        List<JsonNode> rooms = fetchRoomsWithTypes(hotelId);
        Set<Integer> bookedByOthers = getOverlappingBookedRoomIds(hotelId, checkIn, checkOut, excludeBookingId);

        List<JsonNode> result = new ArrayList<>();
        for (JsonNode room : rooms) {
            if (!room.has("id")) {
                continue;
            }
            if (!roomBelongsToHotel(room, hotelId)) {
                continue;
            }
            int roomId = room.get("id").asInt();
            String status = "";
            if (room.has("status") && !room.get("status").isNull()) {
                status = room.get("status").asText();
            }
            boolean isGuestCurrent = guestCurrentRoomId != null && roomId == guestCurrentRoomId;
            if (!isGuestCurrent && !status.isEmpty() && !"available".equalsIgnoreCase(status)) {
                continue;
            }
            if (bookedByOthers.contains(roomId)) {
                continue;
            }
            result.add(room);
        }
        return result;
    }

    /**
     * Build upgrade cards: current room first, then other available rooms sorted by total (JOD).
     */
    public List<UpgradeRoomOption> buildUpgradeRoomOptions(Booking booking) {
        List<UpgradeRoomOption> options = new ArrayList<>();
        if (booking == null || booking.getHotelId() == null || booking.getId() == null
                || booking.getCheckInDate() == null || booking.getCheckOutDate() == null) {
            return options;
        }

        int hotelId = booking.getHotelId();
        int bookingId = booking.getId();
        LocalDate checkIn = booking.getCheckInDate();
        LocalDate checkOut = booking.getCheckOutDate();
        Integer currentRoomId = booking.getRoomId();

        List<JsonNode> available = getAvailableRoomsForHotel(
                hotelId, checkIn, checkOut, bookingId, currentRoomId);

        Map<Integer, Double> priceCache = new HashMap<>();

        List<RoomUpgradeRow> rows = new ArrayList<>();
        for (JsonNode room : available) {
            int roomId = room.get("id").asInt();
            int roomTypeId = room.has("room_type_id") && !room.get("room_type_id").isNull()
                    ? room.get("room_type_id").asInt()
                    : 0;
            if (roomTypeId == 0) {
                continue;
            }
            double total = priceCache.computeIfAbsent(roomTypeId,
                    id -> sumPricingForRoomType(id, checkIn, checkOut));
            rows.add(new RoomUpgradeRow(room, roomId, total));
        }

        if (currentRoomId != null && rows.stream().noneMatch(r -> r.roomId == currentRoomId)) {
            JsonNode fallback = fetchRoomByIdWithTypesForHotel(currentRoomId, hotelId);
            if (fallback != null && roomBelongsToHotel(fallback, hotelId)
                    && fallback.has("room_type_id") && !fallback.get("room_type_id").isNull()) {
                int rtId = fallback.get("room_type_id").asInt();
                double total = priceCache.computeIfAbsent(rtId,
                        id -> sumPricingForRoomType(id, checkIn, checkOut));
                rows.add(new RoomUpgradeRow(fallback, currentRoomId, total));
            }
        }

        if (currentRoomId != null) {
            rows.sort(Comparator
                    .comparing((RoomUpgradeRow r) -> r.roomId != currentRoomId)
                    .thenComparingDouble(r -> r.totalPrice));
        } else {
            rows.sort(Comparator.comparingDouble(r -> r.totalPrice));
        }

        String[] offerBadges = {
                "Best value upgrade",
                "Limited offer",
                "Premium comfort",
                "Most popular choice"
        };
        int upgradeIndex = 0;

        for (RoomUpgradeRow row : rows) {
            UpgradeRoomOption opt = new UpgradeRoomOption();
            boolean isCurrent = currentRoomId != null && row.roomId == currentRoomId;
            opt.setCurrentSelection(isCurrent);
            opt.setRadioValue(isCurrent ? "keep" : String.valueOf(row.roomId));

            JsonNode rt = row.room.has("room_types") && !row.room.get("room_types").isNull()
                    ? row.room.get("room_types")
                    : null;
            String typeName = rt != null && rt.has("name") ? rt.get("name").asText("Room") : "Room";
            String roomNum = row.room.has("room_number") ? row.room.get("room_number").asText("") : "";
            opt.setTitle(typeName + (roomNum.isEmpty() ? "" : (" · " + roomNum)));

            StringBuilder sub = new StringBuilder();
            if (rt != null) {
                if (rt.has("bed_type") && !rt.get("bed_type").isNull()) {
                    sub.append(rt.get("bed_type").asText());
                }
                if (rt.has("max_occupancy") && !rt.get("max_occupancy").isNull()) {
                    if (sub.length() > 0) {
                        sub.append(" · ");
                    }
                    sub.append("Up to ").append(rt.get("max_occupancy").asInt()).append(" guests");
                }
            }
            if (sub.length() == 0) {
                sub.append("Total for your stay");
            }
            opt.setSubtitle(sub.toString());

            opt.setImageUrl(firstImageFromRoomType(rt));
            opt.setFormattedTotal(formatJod(row.totalPrice));

            if (isCurrent) {
                opt.setOfferBadge("Your current room");
            } else {
                String badge = offerBadges[upgradeIndex % offerBadges.length];
                upgradeIndex++;
                double nights = Math.max(1, java.time.temporal.ChronoUnit.DAYS.between(checkIn, checkOut));
                double perNight = row.totalPrice / nights;
                opt.setOfferBadge(badge + " · " + formatJod(perNight) + " / night avg.");
            }
            options.add(opt);
        }

        return options;
    }

    private static class RoomUpgradeRow {
        final JsonNode room;
        final int roomId;
        final double totalPrice;

        RoomUpgradeRow(JsonNode room, int roomId, double totalPrice) {
            this.room = room;
            this.roomId = roomId;
            this.totalPrice = totalPrice;
        }
    }

    /**
     * Validates the room is still available (excluding this booking) and updates {@code room_id} and {@code total_amount}.
     */
    public boolean updateBookingRoomAndTotal(int bookingId, int newRoomId) {
        Booking booking = getBookingById(bookingId);
        if (booking == null || booking.getHotelId() == null
                || booking.getCheckInDate() == null || booking.getCheckOutDate() == null) {
            return false;
        }

        // Upgrades must be strictly "available"; guest's old room is freed by the update.
        List<JsonNode> available = getAvailableRoomsForHotel(
                booking.getHotelId(),
                booking.getCheckInDate(),
                booking.getCheckOutDate(),
                bookingId,
                null);

        boolean allowed = false;
        int roomTypeId = 0;
        int expectedHotelId = booking.getHotelId();
        for (JsonNode room : available) {
            if (room.get("id").asInt() != newRoomId) {
                continue;
            }
            if (!roomBelongsToHotel(room, expectedHotelId)) {
                break;
            }
            allowed = true;
            if (room.has("room_type_id") && !room.get("room_type_id").isNull()) {
                roomTypeId = room.get("room_type_id").asInt();
            }
            break;
        }
        if (!allowed || roomTypeId == 0) {
            return false;
        }

        double newTotal = sumPricingForRoomType(roomTypeId, booking.getCheckInDate(), booking.getCheckOutDate());

        String url = supabaseConfig.getSupabaseUrl() + "/rest/v1/bookings?id=eq." + bookingId;
        HttpHeaders headers = createServiceHeaders();
        headers.set("Prefer", "return=minimal");

        Map<String, Object> body = new HashMap<>();
        body.put("room_id", newRoomId);
        body.put("total_amount", newTotal);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
        try {
            restTemplate.exchange(url, HttpMethod.PATCH, entity, String.class);
            System.out.println("[SUPABASE] Updated booking " + bookingId + " to room " + newRoomId + " total=" + newTotal);
            return true;
        } catch (Exception e) {
            System.out.println("[SUPABASE] updateBookingRoomAndTotal failed: " + e.getMessage());
            return false;
        }
    }

    /**
     * Loads a room only if it belongs to {@code hotelId} (same hotel as the booking).
     */
    private JsonNode fetchRoomByIdWithTypesForHotel(int roomId, int hotelId) {
        String base = supabaseConfig.getSupabaseUrl() + "/rest/v1/rooms";
        UriComponentsBuilder b = UriComponentsBuilder.fromUriString(base)
                .queryParam("id", "eq." + roomId)
                .queryParam("hotel_id", "eq." + hotelId)
                .queryParam("select", "*,room_types(*)");

        HttpEntity<String> entity = new HttpEntity<>(createServiceHeaders());
        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    b.toUriString(), HttpMethod.GET, entity, String.class);
            if (response.getBody() == null) {
                return null;
            }
            JsonNode arr = objectMapper.readTree(response.getBody());
            if (arr.isArray() && arr.size() > 0) {
                return arr.get(0);
            }
        } catch (Exception e) {
            System.out.println("[SUPABASE] fetchRoomByIdWithTypesForHotel failed: " + e.getMessage());
        }
        return null;
    }

    private static boolean roomBelongsToHotel(JsonNode room, int expectedHotelId) {
        if (room == null || !room.has("hotel_id") || room.get("hotel_id").isNull()) {
            return false;
        }
        return room.get("hotel_id").asInt() == expectedHotelId;
    }

    private List<JsonNode> fetchRoomsWithTypes(int hotelId) {
        String base = supabaseConfig.getSupabaseUrl() + "/rest/v1/rooms";
        UriComponentsBuilder b = UriComponentsBuilder.fromUriString(base)
                .queryParam("hotel_id", "eq." + hotelId)
                .queryParam("select", "*,room_types(*)");

        HttpEntity<String> entity = new HttpEntity<>(createServiceHeaders());
        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    b.toUriString(), HttpMethod.GET, entity, String.class);
            if (response.getBody() == null) {
                return List.of();
            }
            JsonNode arr = objectMapper.readTree(response.getBody());
            if (!arr.isArray()) {
                return List.of();
            }
            List<JsonNode> list = new ArrayList<>();
            for (JsonNode n : arr) {
                list.add(n);
            }
            return list;
        } catch (Exception e) {
            System.out.println("[SUPABASE] fetchRoomsWithTypes failed: " + e.getMessage());
            return List.of();
        }
    }

    private Set<Integer> getOverlappingBookedRoomIds(
            int hotelId,
            LocalDate checkIn,
            LocalDate checkOut,
            int excludeBookingId) {

        String base = supabaseConfig.getSupabaseUrl() + "/rest/v1/bookings";
        UriComponentsBuilder b = UriComponentsBuilder.fromUriString(base)
                .queryParam("hotel_id", "eq." + hotelId)
                .queryParam("status", "eq.confirmed")
                .queryParam("select", "id,room_id,check_in_date,check_out_date");

        HttpEntity<String> entity = new HttpEntity<>(createServiceHeaders());
        Set<Integer> booked = new HashSet<>();
        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    b.toUriString(), HttpMethod.GET, entity, String.class);
            if (response.getBody() == null) {
                return booked;
            }
            JsonNode arr = objectMapper.readTree(response.getBody());
            if (!arr.isArray()) {
                return booked;
            }
            for (JsonNode row : arr) {
                int id = row.has("id") ? row.get("id").asInt() : -1;
                if (id == excludeBookingId) {
                    continue;
                }
                if (!row.has("room_id") || row.get("room_id").isNull()) {
                    continue;
                }
                int roomId = row.get("room_id").asInt();
                LocalDate bIn = parseLocalDate(row.get("check_in_date"));
                LocalDate bOut = parseLocalDate(row.get("check_out_date"));
                if (bIn == null || bOut == null) {
                    continue;
                }
                if (bIn.isBefore(checkOut) && bOut.isAfter(checkIn)) {
                    booked.add(roomId);
                }
            }
        } catch (Exception e) {
            System.out.println("[SUPABASE] getOverlappingBookedRoomIds failed: " + e.getMessage());
        }
        return booked;
    }

    private static LocalDate parseLocalDate(JsonNode node) {
        if (node == null || node.isNull()) {
            return null;
        }
        String s = node.asText();
        if (s == null || s.isEmpty()) {
            return null;
        }
        if (s.length() >= 10) {
            s = s.substring(0, 10);
        }
        try {
            return LocalDate.parse(s, ISO_DATE);
        } catch (Exception e) {
            return null;
        }
    }

    private double sumPricingForRoomType(int roomTypeId, LocalDate checkIn, LocalDate checkOut) {
        String in = checkIn.format(ISO_DATE);
        String out = checkOut.format(ISO_DATE);
        String base = supabaseConfig.getSupabaseUrl() + "/rest/v1/pricing";
        UriComponentsBuilder b = UriComponentsBuilder.fromUriString(base)
                .queryParam("room_type_id", "eq." + roomTypeId)
                .queryParam("date", "gte." + in)
                .queryParam("date", "lt." + out)
                .queryParam("select", "date,price");

        HttpEntity<String> entity = new HttpEntity<>(createServiceHeaders());
        Map<LocalDate, Double> byDate = new HashMap<>();
        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    b.toUriString(), HttpMethod.GET, entity, String.class);
            if (response.getBody() != null) {
                JsonNode arr = objectMapper.readTree(response.getBody());
                if (arr.isArray()) {
                    for (JsonNode row : arr) {
                        LocalDate d = parseLocalDate(row.get("date"));
                        if (d == null || !d.isBefore(checkOut) || d.isBefore(checkIn)) {
                            continue;
                        }
                        double p = 0;
                        if (row.has("price") && !row.get("price").isNull()) {
                            p = row.get("price").asDouble();
                        }
                        byDate.put(d, p);
                    }
                }
            }
        } catch (Exception e) {
            System.out.println("[SUPABASE] sumPricingForRoomType fetch failed: " + e.getMessage());
        }

        double total = 0;
        for (LocalDate d = checkIn; d.isBefore(checkOut); d = d.plusDays(1)) {
            total += byDate.getOrDefault(d, 0.0);
        }
        return total;
    }

    private static String firstImageFromRoomType(JsonNode rt) {
        if (rt == null || !rt.has("images") || rt.get("images").isNull()) {
            return "https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=900&q=80";
        }
        JsonNode imgs = rt.get("images");
        if (imgs.isArray() && imgs.size() > 0) {
            return imgs.get(0).asText();
        }
        return "https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=900&q=80";
    }
}