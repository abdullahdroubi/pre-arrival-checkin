package com.petrabooking.checkin.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.time.LocalDate;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class Booking {

    private Integer id;

    @JsonProperty("booking_reference")
    private String bookingReference;

    @JsonProperty("guest_email")
    private String guestEmail;

    @JsonProperty("guest_first_name")
    private String guestFirstName;

    @JsonProperty("guest_last_name")
    private String guestLastName;

    @JsonProperty("check_in_date")
    private LocalDate checkInDate;

    @JsonProperty("check_out_date")
    private LocalDate checkOutDate;

    @JsonProperty("number_of_guests")
    private Integer numberOfGuests;

    @JsonProperty("total_amount")
    private Double totalAmount;

    private String status;

    @JsonProperty("hotel_id")
    private Integer hotelId;

    @JsonProperty("room_id")
    private Integer roomId;
}