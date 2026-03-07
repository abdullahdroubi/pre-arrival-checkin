package com.petrabooking.checkin.controller;

import com.petrabooking.checkin.model.Booking;
import com.petrabooking.checkin.model.Hotel;
import com.petrabooking.checkin.service.SupabaseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

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

        return "checkin-form";
    }

    @PostMapping("/submit")
    public String submitCheckIn(@RequestParam Map<String, String> formData) {
        Map<String, Object> checkInData = new HashMap<>(formData);
        supabaseService.submitCheckIn(checkInData);
        return "redirect:/checkin/confirmation?booking=" + formData.get("bookingReference");
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
}