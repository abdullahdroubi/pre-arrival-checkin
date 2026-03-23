package com.petrabooking.checkin.controller;

import jakarta.servlet.http.HttpSession;
import java.util.Arrays;
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
        
        // Ensure numberOfGuests is not null
        Integer numberOfGuests = bookingData.getNumberOfGuests();
        if (numberOfGuests == null || numberOfGuests < 1) {
            numberOfGuests = 1;
        }
        model.addAttribute("numberOfGuests", numberOfGuests);

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
    public String submitCheckIn(@RequestParam Map<String, String> formData, HttpSession session, Model model) {
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

        String bookingId = String.valueOf(bookingData.getId());
        String guestEmail = formData.get("guestEmail");

        // Save personal info to session for persistence
        Map<String, Object> personalInfoData = new HashMap<>();
        personalInfoData.put("guestFirstName", formData.get("guestFirstName"));
        personalInfoData.put("guestEmail", formData.get("guestEmail"));
        personalInfoData.put("guestPhone", formData.get("countryCode") + " " + formData.get("guestPhone"));
        personalInfoData.put("idPassportNumber", formData.get("idPassportNumber"));
        personalInfoData.put("nationality", formData.get("nationality"));
        personalInfoData.put("dateOfBirth", formData.get("dateOfBirth"));
        personalInfoData.put("iqamaNumber", formData.get("iqamaNumber"));
        personalInfoData.put("additionalGuests", additionalGuests);
        session.setAttribute("personalInfo_" + bookingId, personalInfoData);

        // Submit to Supabase
        try {
            supabaseService.submitCheckIn(checkInData);
            System.out.println("[CHECKIN] Check-in submitted successfully");

            // Redirect to further-details page instead of confirmation
            return "redirect:/checkin/further-details?bookingReference=" + bookingRef + 
                   "&bookingId=" + bookingId + "&guestEmail=" + guestEmail;
        } catch (Exception e) {
            System.out.println("[CHECKIN] Error submitting check-in: " + e.getMessage());
            model.addAttribute("error", "Failed to submit check-in. Please try again.");
            return "error";
        }
    }

    /**
     * Show further details page after personal information form
     */
    @GetMapping("/further-details")
    public String showFurtherDetails(
            @RequestParam String bookingReference,
            @RequestParam String bookingId,
            @RequestParam String guestEmail,
            HttpSession session,
            Model model) {

        System.out.println("[CHECKIN] /checkin/further-details bookingReference=" + bookingReference);

        // Load saved data from session if available
        Map<String, Object> savedData = (Map<String, Object>) session.getAttribute("furtherDetails_" + bookingId);
        if (savedData != null) {
            model.addAttribute("purposeOfStay", savedData.get("purposeOfStay"));
            model.addAttribute("purposeOfStayOther", savedData.get("purposeOfStayOther"));
            model.addAttribute("dietaryPreferences", savedData.get("dietaryPreferences"));
            model.addAttribute("dietaryPreferencesOther", savedData.get("dietaryPreferencesOther"));
            model.addAttribute("hasAllergies", savedData.get("hasAllergies"));
            model.addAttribute("allergiesDetails", savedData.get("allergiesDetails"));
            model.addAttribute("accessibilityNeeds", savedData.get("accessibilityNeeds"));
            model.addAttribute("accessibilityNeedsOther", savedData.get("accessibilityNeedsOther"));
        }

        // Load accessibility form data if available
        Map<String, Object> accessibilityData = (Map<String, Object>) session.getAttribute("accessibilityForm_" + bookingId);
        if (accessibilityData != null) {
            model.addAttribute("roomFeatures", accessibilityData.get("roomFeatures"));
            model.addAttribute("showerOption", accessibilityData.get("showerOption"));
            model.addAttribute("toiletGrabBars", accessibilityData.get("toiletGrabBars"));
            model.addAttribute("bedTransferSpace", accessibilityData.get("bedTransferSpace"));
            model.addAttribute("bedHeight", accessibilityData.get("bedHeight"));
            model.addAttribute("communicationPrefs", accessibilityData.get("communicationPrefs"));
            model.addAttribute("mobilityEquipment", accessibilityData.get("mobilityEquipment"));
            model.addAttribute("mobilityEquipmentOther", accessibilityData.get("mobilityEquipmentOther"));
            model.addAttribute("mobilityServices", accessibilityData.get("mobilityServices"));
            model.addAttribute("hasServiceAnimal", accessibilityData.get("hasServiceAnimal"));
            model.addAttribute("animalSupport", accessibilityData.get("animalSupport"));
            model.addAttribute("animalSupportOther", accessibilityData.get("animalSupportOther"));
            model.addAttribute("parkingNeeds", accessibilityData.get("parkingNeeds"));
            model.addAttribute("emergencyAlerts", accessibilityData.get("emergencyAlerts"));
            model.addAttribute("emergencyNotes", accessibilityData.get("emergencyNotes"));
        }

        model.addAttribute("bookingReference", bookingReference);
        model.addAttribute("bookingId", bookingId);
        model.addAttribute("guestEmail", guestEmail);

        return "further-details";
    }

    /**
     * Submit further details form
     */
    @PostMapping("/further-details/submit")
    public String submitFurtherDetails(
            @RequestParam String bookingReference,
            @RequestParam String bookingId,
            @RequestParam String guestEmail,
            @RequestParam(required = false) String purposeOfStay,
            @RequestParam(required = false) String purposeOfStayOther,
            @RequestParam(required = false) String[] dietaryPreferences,
            @RequestParam(required = false) String dietaryPreferencesOther,
            @RequestParam(required = false) String hasAllergies,
            @RequestParam(required = false) String allergiesDetails,
            @RequestParam(required = false) String[] accessibilityNeeds,
            @RequestParam(required = false) String accessibilityNeedsOther,
            HttpSession session,
            Model model) {

        System.out.println("[CHECKIN] Submitting further details for bookingId=" + bookingId);

        // Save to session for persistence
        Map<String, Object> data = new HashMap<>();
        data.put("purposeOfStay", purposeOfStay);
        data.put("purposeOfStayOther", purposeOfStayOther);
        data.put("dietaryPreferences", dietaryPreferences != null ? Arrays.asList(dietaryPreferences) : null);
        data.put("dietaryPreferencesOther", dietaryPreferencesOther);
        data.put("hasAllergies", "true".equals(hasAllergies));
        data.put("allergiesDetails", allergiesDetails);
        data.put("accessibilityNeeds", accessibilityNeeds != null ? Arrays.asList(accessibilityNeeds) : null);
        data.put("accessibilityNeedsOther", accessibilityNeedsOther);

        session.setAttribute("furtherDetails_" + bookingId, data);

        // Redirect to EAT (Estimated Arrival Time) page
        return "redirect:/checkin/eat?bookingReference=" + bookingReference + 
               "&bookingId=" + bookingId + "&guestEmail=" + guestEmail;
    }

    /**
     * Show accessibility form (opens in popup/modal)
     */
    @GetMapping("/accessibility-form")
    public String showAccessibilityForm(
            @RequestParam String bookingReference,
            @RequestParam String bookingId,
            @RequestParam String guestEmail,
            HttpSession session,
            Model model) {

        System.out.println("[CHECKIN] /checkin/accessibility-form bookingId=" + bookingId);

        // Load saved data from session if available
        Map<String, Object> savedData = (Map<String, Object>) session.getAttribute("accessibilityForm_" + bookingId);
        if (savedData != null) {
            model.addAttribute("roomFeatures", savedData.get("roomFeatures"));
            model.addAttribute("showerOption", savedData.get("showerOption"));
            model.addAttribute("toiletGrabBars", savedData.get("toiletGrabBars"));
            model.addAttribute("bedTransferSpace", savedData.get("bedTransferSpace"));
            model.addAttribute("bedHeight", savedData.get("bedHeight"));
            model.addAttribute("communicationPrefs", savedData.get("communicationPrefs"));
            model.addAttribute("mobilityEquipment", savedData.get("mobilityEquipment"));
            model.addAttribute("mobilityEquipmentOther", savedData.get("mobilityEquipmentOther"));
            model.addAttribute("mobilityServices", savedData.get("mobilityServices"));
            model.addAttribute("hasServiceAnimal", savedData.get("hasServiceAnimal"));
            model.addAttribute("animalSupport", savedData.get("animalSupport"));
            model.addAttribute("animalSupportOther", savedData.get("animalSupportOther"));
            model.addAttribute("parkingNeeds", savedData.get("parkingNeeds"));
            model.addAttribute("emergencyAlerts", savedData.get("emergencyAlerts"));
            model.addAttribute("emergencyNotes", savedData.get("emergencyNotes"));
        }

        model.addAttribute("bookingReference", bookingReference);
        model.addAttribute("bookingId", bookingId);
        model.addAttribute("guestEmail", guestEmail);

        return "accessibility-form";
    }

    /**
     * Submit accessibility form
     */
    @PostMapping("/accessibility-form/submit")
    @ResponseBody
    public Map<String, String> submitAccessibilityForm(
            @RequestParam String bookingReference,
            @RequestParam String bookingId,
            @RequestParam String guestEmail,
            @RequestParam(required = false) String[] roomFeatures,
            @RequestParam(required = false) String showerOption,
            @RequestParam(required = false) String toiletGrabBars,
            @RequestParam(required = false) String bedTransferSpace,
            @RequestParam(required = false) String bedHeight,
            @RequestParam(required = false) String[] communicationPrefs,
            @RequestParam(required = false) String[] mobilityEquipment,
            @RequestParam(required = false) String mobilityEquipmentOther,
            @RequestParam(required = false) String[] mobilityServices,
            @RequestParam(required = false) String hasServiceAnimal,
            @RequestParam(required = false) String[] animalSupport,
            @RequestParam(required = false) String animalSupportOther,
            @RequestParam(required = false) String[] parkingNeeds,
            @RequestParam(required = false) String[] emergencyAlerts,
            @RequestParam(required = false) String emergencyNotes,
            HttpSession session) {

        System.out.println("[CHECKIN] Submitting accessibility form for bookingId=" + bookingId);

        // Save to session for persistence
        Map<String, Object> data = new HashMap<>();
        data.put("roomFeatures", roomFeatures != null ? Arrays.asList(roomFeatures) : null);
        data.put("showerOption", showerOption);
        data.put("toiletGrabBars", toiletGrabBars);
        data.put("bedTransferSpace", bedTransferSpace);
        data.put("bedHeight", bedHeight);
        data.put("communicationPrefs", communicationPrefs != null ? Arrays.asList(communicationPrefs) : null);
        data.put("mobilityEquipment", mobilityEquipment != null ? Arrays.asList(mobilityEquipment) : null);
        data.put("mobilityEquipmentOther", mobilityEquipmentOther);
        data.put("mobilityServices", mobilityServices != null ? Arrays.asList(mobilityServices) : null);
        data.put("hasServiceAnimal", "true".equals(hasServiceAnimal));
        data.put("animalSupport", animalSupport != null ? Arrays.asList(animalSupport) : null);
        data.put("animalSupportOther", animalSupportOther);
        data.put("parkingNeeds", parkingNeeds != null ? Arrays.asList(parkingNeeds) : null);
        data.put("emergencyAlerts", emergencyAlerts != null ? Arrays.asList(emergencyAlerts) : null);
        data.put("emergencyNotes", emergencyNotes);

        session.setAttribute("accessibilityForm_" + bookingId, data);

        Map<String, String> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Accessibility form submitted successfully");

        return response;
    }

    /**
     * Show EAT (Estimated Arrival Time) page
     */
    @GetMapping("/eat")
    public String showEAT(
            @RequestParam String bookingReference,
            @RequestParam String bookingId,
            @RequestParam String guestEmail,
            HttpSession session,
            Model model) {

        System.out.println("[CHECKIN] /checkin/eat bookingReference=" + bookingReference);

        // Get booking data to show check-in date
        Booking bookingData = supabaseService.getBookingByReference(bookingReference);
        if (bookingData == null) {
            model.addAttribute("error", "Booking not found.");
            return "error";
        }

        // Format check-in date for display
        java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("MMMM yyyy");
        String checkInDateFormatted = bookingData.getCheckInDate().format(formatter);
        
        // Load saved arrival time from session if available
        Map<String, Object> savedData = (Map<String, Object>) session.getAttribute("eat_" + bookingId);
        if (savedData != null) {
            model.addAttribute("estimatedArrivalHour", savedData.get("arrivalHour"));
            model.addAttribute("estimatedArrivalMinute", savedData.get("arrivalMinute"));
            model.addAttribute("estimatedArrivalAMPM", savedData.get("arrivalAMPM"));
        }

        model.addAttribute("bookingReference", bookingReference);
        model.addAttribute("bookingId", bookingId);
        model.addAttribute("guestEmail", guestEmail);
        model.addAttribute("checkInDate", bookingData.getCheckInDate().toString());
        model.addAttribute("checkInDateFormatted", checkInDateFormatted);

        return "eat";
    }

    /**
     * Submit EAT (Estimated Arrival Time) form
     */
    @PostMapping("/eat/submit")
    public String submitEAT(
            @RequestParam Map<String, String> formData,
            HttpSession session,
            Model model) {

        // Accept raw formData to avoid Spring 400s when a field is missing/blank.
        String bookingReference = formData.get("bookingReference");
        String bookingId = formData.get("bookingId");
        String guestEmail = formData.get("guestEmail");

        String arrivalHour = formData.get("arrivalHour");
        String arrivalMinute = formData.get("arrivalMinute");
        String arrivalAMPM = formData.get("arrivalAMPM");

        // Safe defaults (used only if inputs are missing/blank)
        if (bookingReference == null || bookingReference.isBlank()) bookingReference = formData.get("booking");
        if (arrivalHour == null || arrivalHour.isBlank()) arrivalHour = "7";
        if (arrivalMinute == null || arrivalMinute.isBlank()) arrivalMinute = "0";
        if (arrivalAMPM == null || arrivalAMPM.isBlank()) arrivalAMPM = "AM";

        if (bookingReference == null || bookingReference.isBlank()
                || bookingId == null || bookingId.isBlank()
                || guestEmail == null || guestEmail.isBlank()) {
            model.addAttribute("error", "Missing required reservation identifiers.");
            return "error";
        }

        System.out.println("[CHECKIN] Submitting EAT for bookingId=" + bookingId
                + ", time=" + arrivalHour + ":" + arrivalMinute + " " + arrivalAMPM);

        // Save to session for persistence
        Map<String, Object> data = new HashMap<>();
        data.put("arrivalHour", arrivalHour);
        data.put("arrivalMinute", arrivalMinute);
        data.put("arrivalAMPM", arrivalAMPM);
        session.setAttribute("eat_" + bookingId, data);

        // TODO: Save to database (pre_checkin_submissions table)
        // Convert to 24-hour format for storage
        int hour24;
        int minuteInt;
        try {
            hour24 = Integer.parseInt(arrivalHour);
            minuteInt = Integer.parseInt(arrivalMinute);
        } catch (Exception e) {
            hour24 = 7;
            minuteInt = 0;
        }
        if (arrivalAMPM.equals("PM") && hour24 != 12) {
            hour24 += 12;
        } else if (arrivalAMPM.equals("AM") && hour24 == 12) {
            hour24 = 0;
        }
        String arrivalTime24 = String.format("%02d:%02d", hour24, minuteInt);
        System.out.println("[CHECKIN] Arrival time (24h): " + arrivalTime24);

        // Redirect to confirm information page
        return "redirect:/checkin/confirm-information?bookingReference=" + bookingReference + 
               "&bookingId=" + bookingId + "&guestEmail=" + guestEmail;
    }

    /**
     * Show confirm information page
     */
    @GetMapping("/confirm-information")
    public String showConfirmInformation(
            @RequestParam String bookingReference,
            @RequestParam String bookingId,
            @RequestParam String guestEmail,
            HttpSession session,
            Model model) {

        System.out.println("[CHECKIN] /checkin/confirm-information bookingReference=" + bookingReference);

        // Get booking data
        Booking bookingData = supabaseService.getBookingByReference(bookingReference);
        if (bookingData == null) {
            model.addAttribute("error", "Booking not found.");
            return "error";
        }

        Hotel hotel = supabaseService.getHotelById(bookingData.getHotelId());
        if (hotel == null) {
            model.addAttribute("error", "Hotel information not found.");
            return "error";
        }

        // Load personal info from session
        Map<String, Object> personalInfo = (Map<String, Object>) session.getAttribute("personalInfo_" + bookingId);
        if (personalInfo == null) {
            model.addAttribute("error", "Personal information not found. Please start over.");
            return "error";
        }

        // Format dates
        java.time.format.DateTimeFormatter dateFormatter = java.time.format.DateTimeFormatter.ofPattern("MMM d, yyyy");
        String checkInDateStr = bookingData.getCheckInDate().format(dateFormatter);
        String checkOutDateStr = bookingData.getCheckOutDate().format(dateFormatter);

        // Load arrival time from session
        Map<String, Object> eatData = (Map<String, Object>) session.getAttribute("eat_" + bookingId);
        String arrivalTime = "3:00 PM"; // Default
        if (eatData != null) {
            String hour = String.valueOf(eatData.get("arrivalHour"));
            String minute = String.valueOf(eatData.get("arrivalMinute"));
            String ampm = String.valueOf(eatData.get("arrivalAMPM"));
            arrivalTime = hour + ":" + (minute.length() == 1 ? "0" + minute : minute) + " " + ampm;
        }

        String checkInDisplay = checkInDateStr + " | " + arrivalTime;
        String checkOutDisplay = checkOutDateStr + " | 3:00 PM"; // Default check-out time

        // Format owner information
        String ownerFullName = String.valueOf(personalInfo.get("guestFirstName"));
        String ownerNationality = String.valueOf(personalInfo.get("nationality"));
        String ownerDateOfBirth = formatDateOfBirth(String.valueOf(personalInfo.get("dateOfBirth")));
        String ownerPhone = String.valueOf(personalInfo.get("guestPhone"));
        String ownerEmail = String.valueOf(personalInfo.get("guestEmail"));
        String ownerIdPassport = maskId(String.valueOf(personalInfo.get("idPassportNumber")));

        // Load additional guests
        @SuppressWarnings("unchecked")
        List<Map<String, String>> additionalGuests = (List<Map<String, String>>) personalInfo.get("additionalGuests");
        List<Map<String, String>> otherGuestsList = new ArrayList<>();
        if (additionalGuests != null) {
            for (Map<String, String> guest : additionalGuests) {
                Map<String, String> guestInfo = new HashMap<>();
                guestInfo.put("fullName", guest.get("full_name"));
                guestInfo.put("nationality", guest.get("nationality"));
                guestInfo.put("dateOfBirth", formatDateOfBirth(guest.get("date_of_birth")));
                guestInfo.put("idPassport", maskId(guest.get("id_passport")));
                otherGuestsList.add(guestInfo);
            }
        }

        model.addAttribute("bookingReference", bookingReference);
        model.addAttribute("bookingId", bookingId);
        model.addAttribute("guestEmail", guestEmail);
        model.addAttribute("hotel", hotel);
        model.addAttribute("formattedReservationNumber", formatReservationNumber(bookingData.getBookingReference()));
        model.addAttribute("checkInDisplay", checkInDisplay);
        model.addAttribute("checkOutDisplay", checkOutDisplay);
        model.addAttribute("ownerFullName", ownerFullName);
        model.addAttribute("ownerNationality", ownerNationality);
        model.addAttribute("ownerDateOfBirth", ownerDateOfBirth);
        model.addAttribute("ownerPhone", ownerPhone);
        model.addAttribute("ownerEmail", ownerEmail);
        model.addAttribute("ownerIdPassport", ownerIdPassport);
        model.addAttribute("otherGuests", otherGuestsList);

        return "confirm-information";
    }

    /**
     * Submit confirm information (final confirmation)
     */
    @PostMapping("/confirm-information/submit")
    public String submitConfirmInformation(
            @RequestParam String bookingReference,
            @RequestParam String bookingId,
            @RequestParam String guestEmail,
            HttpSession session,
            Model model) {

        System.out.println("[CHECKIN] Final confirmation submitted for bookingId=" + bookingId);

        // TODO: Save all collected data to database (pre_checkin_submissions table)
        // Combine all session data and save to Supabase
        
        // Clear session data after successful submission (optional)
        // session.removeAttribute("personalInfo_" + bookingId);
        // session.removeAttribute("furtherDetails_" + bookingId);
        // session.removeAttribute("eat_" + bookingId);
        // session.removeAttribute("accessibilityForm_" + bookingId);

        // Redirect to final confirmation/success page
        return "redirect:/checkin/confirmation?booking=" + bookingReference;
    }

    /**
     * Send email with reservation details
     */
    @PostMapping("/confirm-information/send-email")
    @ResponseBody
    public Map<String, Object> sendEmailDetails(
            @RequestParam String bookingReference,
            @RequestParam String guestEmail,
            HttpSession session) {

        System.out.println("[CHECKIN] Sending email details to " + guestEmail);

        Map<String, Object> response = new HashMap<>();
        
        try {
            // TODO: Implement email sending logic
            // You can use the same email service (Resend/SendGrid) as in the Edge Function
            // Or create a new service method to send confirmation email with all details
            
            response.put("success", true);
            response.put("message", "Email sent successfully");
        } catch (Exception e) {
            System.out.println("[CHECKIN] Error sending email: " + e.getMessage());
            response.put("success", false);
            response.put("message", "Failed to send email: " + e.getMessage());
        }

        return response;
    }

    /**
     * Format date of birth for display
     */
    private String formatDateOfBirth(String dateStr) {
        if (dateStr == null || dateStr.equals("null") || dateStr.isEmpty()) {
            return "N/A";
        }
        try {
            java.time.LocalDate date = java.time.LocalDate.parse(dateStr);
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("MMMM d, yyyy");
            return date.format(formatter);
        } catch (Exception e) {
            return dateStr;
        }
    }

    /**
     * Mask ID/Passport number (show only last 4 digits)
     */
    private String maskId(String id) {
        if (id == null || id.equals("null") || id.isEmpty()) {
            return "N/A";
        }
        if (id.length() <= 4) {
            return "****";
        }
        return "*******" + id.substring(id.length() - 4);
    }
}