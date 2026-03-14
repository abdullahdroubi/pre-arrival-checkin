# Date Change Logic Solution

## Current Implementation
The check-in date is **read-only** and cannot be changed by the user. This is the recommended approach because:

1. **Booking Integrity**: The date is part of the original booking contract
2. **Room Availability**: Changing dates requires checking if the room is available on the new date
3. **Pricing**: Different dates may have different rates
4. **Business Rules**: Hotels typically require date changes to go through customer service

## If You Want to Allow Date Changes

If you decide to allow users to change their check-in date, here's the logic solution:

### Option 1: Simple Availability Check (Recommended)

```java
/**
 * Check if room is available for new check-in date
 */
public boolean isRoomAvailableForDate(int roomId, LocalDate newCheckInDate, LocalDate checkOutDate, int currentBookingId) {
    // Get all confirmed bookings for this room
    String url = supabaseConfig.getSupabaseUrl() + "/rest/v1/bookings";
    UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(url)
            .queryParam("room_id", "eq." + roomId)
            .queryParam("status", "eq.confirmed")
            .queryParam("select", "id,check_in_date,check_out_date");

    HttpEntity<String> entity = new HttpEntity<>(createServiceHeaders());

    try {
        ResponseEntity<Booking[]> response = restTemplate.exchange(
                builder.toUriString(),
                HttpMethod.GET,
                entity,
                Booking[].class
        );

        Booking[] bookings = response.getBody();
        if (bookings == null) return true;

        // Check for date overlaps (excluding current booking)
        for (Booking booking : bookings) {
            if (booking.getId().equals(currentBookingId)) {
                continue; // Skip current booking
            }
            
            LocalDate bookingCheckIn = booking.getCheckInDate();
            LocalDate bookingCheckOut = booking.getCheckOutDate();
            
            // Check if new dates overlap with existing booking
            if (newCheckInDate.isBefore(bookingCheckOut) && checkOutDate.isAfter(bookingCheckIn)) {
                return false; // Room is booked for these dates
            }
        }
        
        return true; // Room is available
    } catch (Exception e) {
        System.out.println("[SUPABASE] Error checking availability: " + e.getMessage());
        return false; // On error, assume not available
    }
}
```

### Option 2: Full Date Change with Validation

Add this method to `CheckInController`:

```java
@PostMapping("/change-date")
@ResponseBody
public Map<String, Object> changeCheckInDate(
        @RequestParam String bookingReference,
        @RequestParam String bookingId,
        @RequestParam String newCheckInDate,
        @RequestParam String newCheckOutDate,
        HttpSession session,
        Model model) {

    Map<String, Object> response = new HashMap<>();
    
    try {
        Booking bookingData = supabaseService.getBookingByReference(bookingReference);
        if (bookingData == null) {
            response.put("success", false);
            response.put("message", "Booking not found");
            return response;
        }

        LocalDate newCheckIn = LocalDate.parse(newCheckInDate);
        LocalDate newCheckOut = LocalDate.parse(newCheckOutDate);
        
        // Validate dates
        if (newCheckIn.isAfter(newCheckOut)) {
            response.put("success", false);
            response.put("message", "Check-in date must be before check-out date");
            return response;
        }
        
        if (newCheckIn.isBefore(LocalDate.now())) {
            response.put("success", false);
            response.put("message", "Check-in date cannot be in the past");
            return response;
        }

        // Check room availability
        boolean isAvailable = supabaseService.isRoomAvailableForDate(
            bookingData.getRoomId(),
            newCheckIn,
            newCheckOut,
            bookingData.getId()
        );

        if (!isAvailable) {
            response.put("success", false);
            response.put("message", "Room is not available for the selected dates. Please choose different dates.");
            return response;
        }

        // Update booking dates in Supabase
        Map<String, Object> updateData = new HashMap<>();
        updateData.put("check_in_date", newCheckIn.toString());
        updateData.put("check_out_date", newCheckOut.toString());
        
        // Call SupabaseService to update booking
        // supabaseService.updateBooking(bookingData.getId(), updateData);

        response.put("success", true);
        response.put("message", "Check-in date updated successfully");
        response.put("newCheckInDate", newCheckIn.toString());
        response.put("newCheckOutDate", newCheckOut.toString());
        
        return response;
        
    } catch (Exception e) {
        response.put("success", false);
        response.put("message", "Error updating date: " + e.getMessage());
        return response;
    }
}
```

### Option 3: Request Date Change (Requires Admin Approval)

If you want date changes to require approval:

1. **Create a date change request table** in Supabase:
```sql
CREATE TABLE date_change_requests (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER REFERENCES bookings(id),
    original_check_in_date DATE,
    original_check_out_date DATE,
    requested_check_in_date DATE,
    requested_check_out_date DATE,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    created_at TIMESTAMP DEFAULT NOW(),
    reviewed_at TIMESTAMP,
    reviewed_by INTEGER
);
```

2. **User submits request** instead of directly changing
3. **Admin reviews and approves/rejects** in admin dashboard
4. **If approved**, update the booking dates

## Recommendation

**Keep the date read-only** for the following reasons:

1. **Simpler Implementation**: No need for complex availability checks
2. **Better UX**: Users know their booking is confirmed for specific dates
3. **Business Control**: Hotels can manage date changes through customer service
4. **Prevents Conflicts**: No risk of double-booking or availability issues
5. **Pricing Consistency**: Original booking price is maintained

If users need to change dates, they should contact customer service, who can:
- Check availability
- Handle pricing differences
- Update the booking properly
- Send confirmation

## Implementation Status

✅ **Current**: Date is read-only (recommended)
❌ **Not Implemented**: Date change functionality (can be added if needed)

If you want to implement date changes, use **Option 1** for a simple solution or **Option 3** for a more controlled approach with admin approval.
