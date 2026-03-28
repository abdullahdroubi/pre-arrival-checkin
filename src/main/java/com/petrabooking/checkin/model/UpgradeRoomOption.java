package com.petrabooking.checkin.model;

import lombok.Data;

/**
 * One selectable room on the pre-arrival upgrade step (Thymeleaf).
 */
@Data
public class UpgradeRoomOption {

    /** Form value: "keep" for current booking room, else physical room id. */
    private String radioValue;

    private boolean currentSelection;
    private String title;
    private String subtitle;
    private String imageUrl;
    /** Display total for stay, e.g. "1,250.00 JD". */
    private String formattedTotal;
    private String offerBadge;
}
