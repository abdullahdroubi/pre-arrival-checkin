// ADD THESE METHODS TO YOUR CheckInController.java
// This file shows the code you need to add to handle further-details and accessibility-form routes

package com.petrabooking.checkin.controller;

import com.petrabooking.checkin.service.SupabaseService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/checkin")
public class CheckInController {

    @Autowired
    private SupabaseService supabaseService;

    // ... existing methods ...

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
        Map<String, Object> data = new java.util.HashMap<>();
        data.put("purposeOfStay", purposeOfStay);
        data.put("purposeOfStayOther", purposeOfStayOther);
        data.put("dietaryPreferences", dietaryPreferences != null ? Arrays.asList(dietaryPreferences) : null);
        data.put("dietaryPreferencesOther", dietaryPreferencesOther);
        data.put("hasAllergies", "true".equals(hasAllergies));
        data.put("allergiesDetails", allergiesDetails);
        data.put("accessibilityNeeds", accessibilityNeeds != null ? Arrays.asList(accessibilityNeeds) : null);
        data.put("accessibilityNeedsOther", accessibilityNeedsOther);

        session.setAttribute("furtherDetails_" + bookingId, data);

        // TODO: Save to database (pre_checkin_submissions table)
        // For now, we'll just redirect to the next step
        // In a real implementation, you'd save this to Supabase

        // Redirect to next step (EAT page - you'll need to create this)
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
        Map<String, Object> data = new java.util.HashMap<>();
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

        // TODO: Save to database (pre_checkin_submissions table)
        // For now, we'll just return success
        // In a real implementation, you'd save this to Supabase

        Map<String, String> response = new java.util.HashMap<>();
        response.put("status", "success");
        response.put("message", "Accessibility form submitted successfully");

        return response;
    }

    /**
     * Update existing submitCheckIn to redirect to further-details instead of confirmation
     */
    // Modify your existing submitCheckIn method to redirect like this:
    /*
    @PostMapping("/submit")
    public String submitCheckIn(
            // ... existing parameters ...
            HttpSession session,
            Model model) {
        
        // ... existing code to save personal information ...
        
        // Save personal info to session
        session.setAttribute("personalInfo_" + bookingId, personalInfoData);
        
        // Redirect to further-details page
        return "redirect:/checkin/further-details?bookingReference=" + bookingReference + 
               "&bookingId=" + bookingId + "&guestEmail=" + guestEmail;
    }
    */
}
