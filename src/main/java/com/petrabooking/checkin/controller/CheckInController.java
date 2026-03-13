package com.petrabooking.checkin.controller;

import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.petrabooking.checkin.model.Booking;
import com.petrabooking.checkin.model.Hotel;
import com.petrabooking.checkin.service.SupabaseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/checkin")
public class CheckInController {

    @Autowired
    private SupabaseService supabaseService;

    @GetMapping
    public String showHomePage(
            @RequestParam String booking,
            @RequestParam String email,
            Model model) {

        System.out.println("[CHECKIN] /checkin booking=" + booking + ", email=" + email);

        Booking bookingData = supabaseService.getBookingByReference(booking);
        if (bookingData == null) {
            model.addAttribute("error", "Booking not found. Please check your booking reference.");
            return "error";
        }

        if (bookingData.getGuestEmail() == null ||
                !bookingData.getGuestEmail().trim().equalsIgnoreCase(email.trim())) {
            model.addAttribute("error", "Email does not match this booking.");
            return "error";
        }

        if (bookingData.getHotelId() == null) {
            model.addAttribute("error", "Hotel ID is missing for this booking.");
            return "error";
        }

        Hotel hotel = supabaseService.getHotelById(bookingData.getHotelId());
        if (hotel == null) {
            model.addAttribute("error", "Hotel information not found.");
            return "error";
        }

        model.addAttribute("booking", bookingData);
        model.addAttribute("hotel", hotel);
        model.addAttribute("guestName",
                (bookingData.getGuestFirstName() == null ? "" : bookingData.getGuestFirstName()) + " " +
                        (bookingData.getGuestLastName() == null ? "" : bookingData.getGuestLastName()));
        model.addAttribute("guestEmail", email);

        String formattedRef = formatReservationNumber(bookingData.getBookingReference());
        model.addAttribute("formattedReservationNumber", formattedRef);

        return "home";
    }

    @GetMapping("/form")
    public String showCheckInForm(
            @RequestParam String booking,
            @RequestParam String email,
            Model model) {

        System.out.println("[CHECKIN] /checkin/form booking=" + booking + ", email=" + email);

        Booking bookingData = supabaseService.getBookingByReference(booking);
        if (bookingData == null) {
            model.addAttribute("error", "Booking not found. Please check your booking reference.");
            return "error";
        }

        if (bookingData.getGuestEmail() == null ||
                !bookingData.getGuestEmail().trim().equalsIgnoreCase(email.trim())) {
            model.addAttribute("error", "Email does not match this booking.");
            return "error";
        }

        if (bookingData.getHotelId() == null) {
            model.addAttribute("error", "Hotel ID is missing for this booking.");
            return "error";
        }

        Hotel hotel = supabaseService.getHotelById(bookingData.getHotelId());
        if (hotel == null) {
            model.addAttribute("error", "Hotel information not found.");
            return "error";
        }

        model.addAttribute("booking", bookingData);
        model.addAttribute("hotel", hotel);
        model.addAttribute("guestEmail", email);
        
        // Build guest name safely
        String guestName = "";
        if (bookingData.getGuestFirstName() != null) {
            guestName += bookingData.getGuestFirstName();
        }
        if (bookingData.getGuestLastName() != null) {
            if (!guestName.isEmpty()) guestName += " ";
            guestName += bookingData.getGuestLastName();
        }
        if (guestName.isEmpty()) {
            guestName = "Guest";
        }
        model.addAttribute("guestFullName", guestName);

        return "checkin-form";
    }

    @GetMapping("/confirmation")
    public String showConfirmation(@RequestParam String booking, Model model) {
        System.out.println("[CHECKIN] /checkin/confirmation booking=" + booking);

        Booking bookingData = supabaseService.getBookingByReference(booking);
        if (bookingData == null) {
            model.addAttribute("error", "Booking not found.");
            return "error";
        }

        if (bookingData.getHotelId() == null) {
            model.addAttribute("error", "Hotel ID is missing for this booking.");
            return "error";
        }

        Hotel hotel = supabaseService.getHotelById(bookingData.getHotelId());
        if (hotel == null) {
            model.addAttribute("error", "Hotel information not found.");
            return "error";
        }

        model.addAttribute("booking", bookingData);
        model.addAttribute("hotel", hotel);

        return "confirmation";
    }

    private String formatReservationNumber(String bookingRef) {
        if (bookingRef == null || bookingRef.isBlank()) {
            return "#N/A";
        }
        String numbers = bookingRef.replaceAll("[^0-9]", "");
        if (numbers.length() >= 4) {
            return "#" + numbers.substring(0, 4) + "-" + numbers.substring(4);
        }
        return "#" + bookingRef;
    }
    @PostMapping("/submit")
    public String submitCheckIn(@RequestParam Map<String, String> formData, Model model) {
        System.out.println("[CHECKIN] /checkin/submit - Processing check-in submission");

        // Get booking info
        String bookingRef = formData.get("bookingReference");
        Booking bookingData = supabaseService.getBookingByReference(bookingRef);

        if (bookingData == null) {
            model.addAttribute("error", "Booking not found.");
            return "error";
        }

        // Count guests from form
        int submittedGuests = 1; // Primary guest
        for (String key : formData.keySet()) {
            if (key.startsWith("guest_") && key.contains("_fullName")) {
                submittedGuests++;
            }
        }

        // Prepare check-in data
        Map<String, Object> checkInData = new HashMap<>();

        // Primary guest data
        checkInData.put("booking_id", bookingData.getId());
        checkInData.put("hotel_id", bookingData.getHotelId());
        checkInData.put("guest_full_name", formData.get("guestFirstName"));
        checkInData.put("guest_email", formData.get("guestEmail"));
        checkInData.put("guest_phone", formData.get("countryCode") + " " + formData.get("guestPhone"));
        checkInData.put("id_passport_number", formData.get("idPassportNumber"));
        checkInData.put("nationality", formData.get("nationality"));
        checkInData.put("date_of_birth", formData.get("dateOfBirth"));
        checkInData.put("iqama_number", formData.get("iqamaNumber"));
        checkInData.put("submitted_guests_count", submittedGuests);
        checkInData.put("booked_guests_count", bookingData.getNumberOfGuests());
        checkInData.put("requires_additional_payment", submittedGuests > bookingData.getNumberOfGuests());
        checkInData.put("submitted_at", java.time.LocalDateTime.now().toString());

        // Additional guests data (store as JSON array)
        List<Map<String, String>> additionalGuests = new ArrayList<>();
        for (int i = 2; i <= submittedGuests; i++) {
            Map<String, String> guest = new HashMap<>();
            
            // Required fields
            guest.put("full_name", formData.get("guest_" + i + "_fullName"));
            guest.put("id_passport", formData.get("guest_" + i + "_idPassport"));
            guest.put("nationality", formData.get("guest_" + i + "_nationality"));
            guest.put("date_of_birth", formData.get("guest_" + i + "_dateOfBirth"));
            
            // Optional email - only add if provided
            String email = formData.get("guest_" + i + "_email");
            if (email != null && !email.trim().isEmpty()) {
                guest.put("email", email.trim());
            }
            
            // Optional phone - only add if provided
            String phone = formData.get("guest_" + i + "_phone");
            String countryCode = formData.get("guest_" + i + "_countryCode");
            if (phone != null && !phone.trim().isEmpty() && countryCode != null) {
                guest.put("phone", countryCode + " " + phone.trim());
            }
            
            // Optional iqama - only add if provided
            String iqama = formData.get("guest_" + i + "_iqama");
            if (iqama != null && !iqama.trim().isEmpty()) {
                guest.put("iqama", iqama.trim());
            }
            
            additionalGuests.add(guest);
        }

        if (!additionalGuests.isEmpty()) {
            // Convert to JSON string using Jackson ObjectMapper
            try {
                ObjectMapper mapper = new ObjectMapper();
                checkInData.put("additional_guests", mapper.writeValueAsString(additionalGuests));
            } catch (Exception e) {
                System.out.println("[CHECKIN] Error serializing additional guests: " + e.getMessage());
            }
        }

        // Submit to Supabase
        try {
            supabaseService.submitCheckIn(checkInData);
            System.out.println("[CHECKIN] Check-in submitted successfully");

            // Redirect to confirmation
            return "redirect:/checkin/confirmation?booking=" + bookingRef;
        } catch (Exception e) {
            System.out.println("[CHECKIN] Error submitting check-in: " + e.getMessage());
            model.addAttribute("error", "Failed to submit check-in. Please try again.");
            return "error";
        }
    }
}