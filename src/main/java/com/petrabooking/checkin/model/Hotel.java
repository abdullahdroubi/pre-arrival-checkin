package com.petrabooking.checkin.model;

import lombok.Data;
import java.util.List;

@Data
public class Hotel {
    private Integer id;
    private String name;
    private String address;
    private String city;
    private String country;
    private List<String> images; // Array of image URLs

    // Helper method to get first image as logo
    public String getLogoUrl() {
        return (images != null && !images.isEmpty()) ? images.get(0) : null;
    }
}