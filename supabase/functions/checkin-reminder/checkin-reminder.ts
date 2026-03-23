// Supabase Edge Function for sending booking confirmation and check-in reminder emails
// This function runs on a schedule (cron job) to send pending emails

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Check-in website URL (replace with your actual pre-arrival check-in website URL)
const CHECK_IN_WEBSITE_URL = Deno.env.get("CHECK_IN_WEBSITE_URL") ||
  "https://your-checkin-website.com/checkin";

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Get pending email notifications that are due
    // Only get notifications that haven't been sent yet to prevent duplicates
    const { data: notifications, error: fetchError } = await supabaseClient
      .from("email_notifications")
      .select(`
        *,
        bookings (
          id,
          check_in_date,
          check_out_date,
          number_of_guests,
          total_amount,
          guest_email,
          guest_first_name,
          guest_last_name,
          hotels (
            id,
            name,
            address,
            city,
            country,
            images
          )
        )
      `)
      .eq("email_status", "scheduled")
      .lte("scheduled_date", new Date().toISOString())
      .is("sent_at", null); // Only get emails that haven't been sent yet

    if (fetchError) {
      throw fetchError;
    }

    if (!notifications || notifications.length === 0) {
      return new Response(
        JSON.stringify({ message: "No pending notifications" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        }
      );
    }

    // Process each notification
    const results = [];
    for (const notification of notifications) {
      try {
        const booking = notification.bookings;
        if (!booking || !booking.hotels) continue;

        const hotel = booking.hotels;
        const guestName = `${booking.guest_first_name || ""} ${booking.guest_last_name || ""}`.trim() || "Guest";
        const bookingRef = `BK${String(booking.id).padStart(6, '0')}`;

        // Get hotel logo (first image) or use hotel name
        const hotelLogo = hotel.images && hotel.images.length > 0 ? hotel.images[0] : null;
        const hotelLogoOrName = hotelLogo || hotel.name;

        // Format dates
        const checkInDate = formatDate(booking.check_in_date);
        const checkOutDate = formatDate(booking.check_out_date);
        const checkInTime = "12:00 PM"; // Default check-in time
        const checkOutTime = "3:00 PM"; // Default check-out time

        // Generate check-in URL with booking reference
        const checkInUrl = `${CHECK_IN_WEBSITE_URL}?booking=${bookingRef}&email=${encodeURIComponent(booking.guest_email || "")}`;

        let emailHtml = "";
        let emailSubject = "";

        // Generate email based on type
        if (notification.email_type === "booking_confirmation") {
          emailSubject = `Booking Confirmation - ${bookingRef}`;
          emailHtml = generateConfirmationEmail({
            guestName,
            hotelName: hotel.name,
            hotelLogoOrName,
            hotelAddress: hotel.address || "",
            hotelCity: hotel.city || "",
            hotelCountry: hotel.country || "",
            reservationNumber: bookingRef,
            checkInDate,
            checkOutDate,
            checkInTime,
            checkOutTime,
            numberOfGuests: booking.number_of_guests,
            totalAmount: booking.total_amount,
            checkInUrl,
          });
        } else if (notification.email_type === "check_in_reminder") {
          emailSubject = `Check-in Reminder - Your Stay Awaits`;
          emailHtml = generateCheckInReminderEmail({
            guestName,
            hotelName: hotel.name,
            hotelLogoOrName,
            hotelAddress: hotel.address || "",
            hotelCity: hotel.city || "",
            hotelCountry: hotel.country || "",
            reservationNumber: bookingRef,
            checkInDate,
            checkOutDate,
            checkInTime,
            checkOutTime,
            checkInUrl,
          });
        } else {
          continue; // Skip unknown email types
        }

        // Check if email was already sent (prevent duplicates)
        if (notification.email_status === "sent" || notification.sent_at) {
          console.log(`⏭️ Skipping notification ${notification.id} - already sent`);
          continue;
        }

        // Send email
        const emailSent = await sendEmail({
          to: booking.guest_email || "",
          subject: emailSubject,
          html: emailHtml,
        });

        if (emailSent) {
          // Mark notification as sent immediately to prevent duplicates
          await supabaseClient
            .from("email_notifications")
            .update({
              email_status: "sent",
              sent_at: new Date().toISOString(),
            })
            .eq("id", notification.id);

          results.push({
            notificationId: notification.id,
            emailType: notification.email_type,
            status: "sent",
          });
        } else {
          throw new Error("Email sending failed");
        }
      } catch (error) {
        // Mark notification as failed
        await supabaseClient
          .from("email_notifications")
          .update({
            email_status: "failed",
            error_message: error.message,
          })
          .eq("id", notification.id);

        results.push({
          notificationId: notification.id,
          status: "failed",
          error: error.message,
        });
      }
    }

    return new Response(
      JSON.stringify({
        message: "Processed notifications",
        count: notifications.length,
        results,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});

// Format date to readable string (e.g., "Sep 12, 2025")
function formatDate(dateString: string): string {
  const date = new Date(dateString);
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  return `${months[date.getMonth()]} ${date.getDate()}, ${date.getFullYear()}`;
}

// Generate booking confirmation email HTML
function generateConfirmationEmail({
  guestName,
  hotelName,
  hotelLogoOrName,
  hotelAddress,
  hotelCity,
  hotelCountry,
  reservationNumber,
  checkInDate,
  checkOutDate,
  checkInTime,
  checkOutTime,
  numberOfGuests,
  totalAmount,
  checkInUrl,
}: {
  guestName: string;
  hotelName: string;
  hotelLogoOrName: string | null;
  hotelAddress: string;
  hotelCity: string;
  hotelCountry: string;
  reservationNumber: string;
  checkInDate: string;
  checkOutDate: string;
  checkInTime: string;
  checkOutTime: string;
  numberOfGuests: number;
  totalAmount: number;
  checkInUrl: string;
}): string {
  const hotelLocation = `${hotelAddress}, ${hotelCity}, ${hotelCountry}`;
  const mapQuery = encodeURIComponent(hotelLocation);

  return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Confirmation</title>
    <style>
      @media only screen and (max-width: 620px) {
        .container { width: 100% !important; }
        .mobile-padding { padding: 24px 16px !important; }
        .mobile-stack { display: block !important; width: 100% !important; }
        .mobile-center { text-align: center !important; }
      }
    </style>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, 'Helvetica Neue', Helvetica, sans-serif; background-color: #f4f6f8;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f6f8; padding: 28px 14px;">
        <tr>
            <td align="center">
                <table class="container" width="600" cellpadding="0" cellspacing="0" style="width: 600px; max-width: 600px; background-color: #ffffff; border-radius: 14px; overflow: hidden; border: 1px solid #dde3ea;">
                    <!-- Header -->
                    <tr>
                        <td class="mobile-padding" style="background-color: #12344b; padding: 36px 28px; text-align: center;">
                            ${hotelLogoOrName && hotelLogoOrName.startsWith('http') 
                              ? `<img src="${hotelLogoOrName}" alt="${hotelName}" style="max-width: 170px; max-height: 64px; margin-bottom: 12px; border-radius: 6px;" />`
                              : `<div style="color: #ffffff; font-size: 26px; font-weight: 700; margin-bottom: 12px; letter-spacing: 0.4px;">${hotelLogoOrName || hotelName}</div>`
                            }
                            <div style="color: #ffffff; font-size: 30px; font-weight: 700; margin-bottom: 8px; letter-spacing: 0.6px;">Booking Confirmed</div>
                            <div style="color: #d3e5f1; font-size: 15px; font-weight: 400;">Thank you for choosing us.</div>
                        </td>
                    </tr>

                    <!-- Greeting -->
                    <tr>
                        <td class="mobile-padding" style="padding: 30px 28px 18px 28px;">
                            <p style="margin: 0; font-size: 18px; color: #1c2e3a; font-weight: 700;">Dear ${guestName},</p>
                            <p style="margin: 14px 0 0 0; font-size: 15px; color: #475966; line-height: 1.65;">
                                We are delighted to confirm your reservation at <strong style="color: #2d3748;">${hotelName}</strong>.
                                Your booking has been successfully processed and payment received.
                            </p>
                        </td>
                    </tr>

                    <!-- Reservation Details Card -->
                    <tr>
                        <td class="mobile-padding" style="padding: 0 28px 22px 28px;">
                            <div style="background-color: #f8fbfd; border-radius: 12px; padding: 20px; border: 1px solid #e2e9ef;">
                                <h2 style="margin: 0 0 16px 0; font-size: 20px; color: #1f3443; font-weight: 700; border-bottom: 2px solid #d6e4ee; padding-bottom: 10px;">
                                    Reservation Details
                                </h2>

                                <table width="100%" cellpadding="0" cellspacing="0">
                                    <tr>
                                        <td class="mobile-stack" style="width: 50%; vertical-align: top; padding-right: 8px;">
                                            <div style="margin-bottom: 12px; background: #ffffff; padding: 14px; border-radius: 8px; border: 1px solid #e3eaf0;">
                                                <div style="color: #667784; font-size: 11px; text-transform: uppercase; letter-spacing: 0.4px; margin-bottom: 7px; font-weight: 700;">Hotel</div>
                                                <div style="color: #203646; font-size: 16px; font-weight: 700; margin-bottom: 5px;">${hotelName}</div>
                                                <div style="color: #667784; font-size: 13px; margin-bottom: 8px; line-height: 1.5;">${hotelLocation}</div>
                                                <a href="https://www.google.com/maps/search/?api=1&query=${mapQuery}"
                                                   style="color: #1c5a80; text-decoration: none; font-size: 13px; font-weight: 700;">View on Map</a>
                                            </div>
                                            <div style="background: #ffffff; padding: 14px; border-radius: 8px; border: 1px solid #e3eaf0;">
                                                <div style="color: #667784; font-size: 11px; text-transform: uppercase; letter-spacing: 0.4px; margin-bottom: 7px; font-weight: 700;">Reservation Number</div>
                                                <div style="color: #203646; font-size: 19px; font-weight: 700; letter-spacing: 0.6px;">${reservationNumber}</div>
                                            </div>
                                        </td>
                                        <td class="mobile-stack" style="width: 50%; vertical-align: top; padding-left: 8px;">
                                            <div style="margin-bottom: 12px; background: #ffffff; padding: 14px; border-radius: 8px; border: 1px solid #e3eaf0;">
                                                <div style="color: #667784; font-size: 11px; text-transform: uppercase; letter-spacing: 0.4px; margin-bottom: 7px; font-weight: 700;">Check-in</div>
                                                <div style="color: #203646; font-size: 17px; font-weight: 700; margin-bottom: 4px;">${checkInDate}</div>
                                                <div style="color: #667784; font-size: 13px;">${checkInTime}</div>
                                            </div>
                                            <div style="margin-bottom: 12px; background: #ffffff; padding: 14px; border-radius: 8px; border: 1px solid #e3eaf0;">
                                                <div style="color: #667784; font-size: 11px; text-transform: uppercase; letter-spacing: 0.4px; margin-bottom: 7px; font-weight: 700;">Check-out</div>
                                                <div style="color: #203646; font-size: 17px; font-weight: 700; margin-bottom: 4px;">${checkOutDate}</div>
                                                <div style="color: #667784; font-size: 13px;">${checkOutTime}</div>
                                            </div>
                                            <div style="background: #ffffff; padding: 14px; border-radius: 8px; border: 1px solid #e3eaf0;">
                                                <div style="color: #667784; font-size: 11px; text-transform: uppercase; letter-spacing: 0.4px; margin-bottom: 7px; font-weight: 700;">Guests</div>
                                                <div style="color: #203646; font-size: 17px; font-weight: 700;">${numberOfGuests} ${numberOfGuests === 1 ? 'Guest' : 'Guests'}</div>
                                            </div>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="2" style="padding-top: 14px;">
                                            <div style="background-color: #12344b; padding: 16px; border-radius: 8px; text-align: right;">
                                                <div style="color: #b8cedd; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; font-weight: 700;">Total Amount</div>
                                                <div style="color: #ffffff; font-size: 30px; font-weight: 700;">$${totalAmount.toFixed(2)}</div>
                                            </div>
                                        </td>
                                    </tr>
                                </table>
                            </div>
                        </td>
                    </tr>

                    <!-- Call to Action -->
                    <tr>
                        <td class="mobile-padding mobile-center" style="padding: 0 28px 26px 28px; text-align: center;">
                            <p style="margin: 0 0 12px 0; font-size: 16px; color: #223748; font-weight: 700;">We look forward to welcoming you.</p>
                            <a href="${checkInUrl}" style="display: inline-block; background-color: #12344b; color: #ffffff; text-decoration: none; padding: 12px 24px; border-radius: 8px; font-size: 14px; font-weight: 700;">Manage Booking</a>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f7fafc; padding: 22px; text-align: center; border-top: 1px solid #e1e8ef;">
                            <p style="margin: 0 0 10px 0; font-size: 14px; color: #5a6c79;">
                                Need help? <a href="mailto:support@hotel.com" style="color: #12344b; text-decoration: none; font-weight: 700;">Contact us</a>
                            </p>
                            <p style="margin: 0; font-size: 12px; color: #8ea0ae;">
                                © ${new Date().getFullYear()} ${hotelName}. All rights reserved.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
  `;
}

// Generate check-in reminder email HTML
function generateCheckInReminderEmail({
  guestName,
  hotelName,
  hotelLogoOrName,
  hotelAddress,
  hotelCity,
  hotelCountry,
  reservationNumber,
  checkInDate,
  checkOutDate,
  checkInTime,
  checkOutTime,
  checkInUrl,
}: {
  guestName: string;
  hotelName: string;
  hotelLogoOrName: string | null;
  hotelAddress: string;
  hotelCity: string;
  hotelCountry: string;
  reservationNumber: string;
  checkInDate: string;
  checkOutDate: string;
  checkInTime: string;
  checkOutTime: string;
  checkInUrl: string;
}): string {
  const hotelLocation = `${hotelAddress}, ${hotelCity}, ${hotelCountry}`;
  const mapQuery = encodeURIComponent(hotelLocation);

  return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Check-in Reminder</title>
    <style>
      @media only screen and (max-width: 620px) {
        .container { width: 100% !important; }
        .mobile-padding { padding: 24px 16px !important; }
        .mobile-stack { display: block !important; width: 100% !important; }
      }
    </style>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, 'Helvetica Neue', Helvetica, sans-serif; background-color: #f4f6f8;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f6f8; padding: 28px 14px;">
        <tr>
            <td align="center">
                <table class="container" width="600" cellpadding="0" cellspacing="0" style="width: 600px; max-width: 600px; background-color: #ffffff; border-radius: 14px; overflow: hidden; border: 1px solid #dde3ea;">
                    <!-- Header -->
                    <tr>
                        <td class="mobile-padding" style="background-color: #12344b; padding: 34px 24px; text-align: center;">
                            ${hotelLogoOrName && hotelLogoOrName.startsWith('http') 
                              ? `<img src="${hotelLogoOrName}" alt="${hotelName}" style="max-width: 180px; max-height: 72px; margin-bottom: 10px; border-radius: 6px;" />`
                              : `<div style="color: #ffffff; font-size: 22px; font-weight: 700; margin-bottom: 10px;">${hotelLogoOrName || hotelName}</div>`
                            }
                            <div style="color: #ffffff; font-size: 26px; font-weight: 700; line-height: 1.3;">
                                Your Stay Awaits - Begin Your Seamless Check-In
                            </div>
                        </td>
                    </tr>

                    <!-- Greeting -->
                    <tr>
                        <td class="mobile-padding" style="padding: 28px 24px 18px 24px;">
                            <p style="margin: 0; font-size: 18px; color: #1c2e3a; font-weight: 700;">Dear ${guestName},</p>
                            <p style="margin: 14px 0 0 0; font-size: 15px; color: #495b68; line-height: 1.65;">
                                We are delighted to welcome you to <strong>${hotelName}</strong>.
                                Below are your Reservation details.
                            </p>
                        </td>
                    </tr>

                    <!-- Reservation Details Card -->
                    <tr>
                        <td class="mobile-padding" style="padding: 0 24px 18px 24px;">
                            <div style="background-color: #12344b; border-radius: 10px; padding: 18px;">
                                <h2 style="margin: 0 0 16px 0; font-size: 20px; color: #ffffff; border-bottom: 1px solid #41627a; padding-bottom: 10px;">
                                    Your Reservation Details
                                </h2>

                                <table width="100%" cellpadding="10" cellspacing="0">
                                    <tr>
                                        <td class="mobile-stack" style="width: 50%; vertical-align: top;">
                                            <div style="margin-bottom: 20px;">
                                                <div style="color: #b7cad8; font-size: 12px; margin-bottom: 5px;">Hotel</div>
                                                <div style="color: #ffffff; font-size: 16px; font-weight: bold; margin-bottom: 5px;">${hotelName}</div>
                                                <div style="color: #b7cad8; font-size: 13px; margin-bottom: 5px; line-height: 1.5;">${hotelLocation}</div>
                                                <a href="https://www.google.com/maps/search/?api=1&query=${mapQuery}"
                                                   style="color: #d7e7f3; text-decoration: none; font-size: 13px; font-weight: 700;">View on Map</a>
                                            </div>
                                            <div style="margin-bottom: 20px;">
                                                <div style="color: #b7cad8; font-size: 12px; margin-bottom: 5px;">Reservation Number</div>
                                                <div style="color: #ffffff; font-size: 18px; font-weight: bold;">${reservationNumber}</div>
                                            </div>
                                        </td>
                                        <td class="mobile-stack" style="width: 50%; vertical-align: top;">
                                            <div style="margin-bottom: 20px;">
                                                <div style="color: #b7cad8; font-size: 12px; margin-bottom: 5px;">Check-in</div>
                                                <div style="color: #ffffff; font-size: 16px; font-weight: bold;">${checkInDate}</div>
                                                <div style="color: #b7cad8; font-size: 13px;">${checkInTime}</div>
                                            </div>
                                            <div style="margin-bottom: 20px;">
                                                <div style="color: #b7cad8; font-size: 12px; margin-bottom: 5px;">Check-out</div>
                                                <div style="color: #ffffff; font-size: 16px; font-weight: bold;">${checkOutDate}</div>
                                                <div style="color: #b7cad8; font-size: 13px;">${checkOutTime}</div>
                                            </div>
                                        </td>
                                    </tr>
                                </table>
                            </div>
                        </td>
                    </tr>

                    <!-- Benefits Section -->
                    <tr>
                        <td class="mobile-padding" style="padding: 20px 24px;">
                            <p style="margin: 0 0 18px 0; font-size: 15px; color: #4a5d69; line-height: 1.6;">
                                To make your arrival effortless, we invite you to complete your check-in online before you arrive. This ensures:
                            </p>

                            <table width="100%" cellpadding="10" cellspacing="0" style="margin-bottom: 16px;">
                                <tr>
                                    <td class="mobile-stack" style="width: 33.33%; vertical-align: top; text-align: center;">
                                        <div style="background-color: #eaf2f8; border: 1px solid #c4d7e6; color: #12344b; width: 52px; height: 52px; border-radius: 12px; margin: 0 auto 12px; line-height: 52px; font-size: 13px; font-weight: 700; letter-spacing: 0.7px;">FAST</div>
                                        <div style="font-weight: bold; color: #1f3443; margin-bottom: 8px; font-size: 14px;">A faster, contactless hotel arrival</div>
                                        <div style="color: #666666; font-size: 12px; line-height: 1.4;">Bypass the front desk and go directly to your room</div>
                                    </td>
                                    <td class="mobile-stack" style="width: 33.33%; vertical-align: top; text-align: center;">
                                        <div style="background-color: #eaf2f8; border: 1px solid #c4d7e6; color: #12344b; width: 52px; height: 52px; border-radius: 12px; margin: 0 auto 12px; line-height: 52px; font-size: 13px; font-weight: 700; letter-spacing: 0.7px;">ID</div>
                                        <div style="font-weight: bold; color: #1f3443; margin-bottom: 8px; font-size: 14px;">Seamless and hassle-free ID verification</div>
                                        <div style="color: #666666; font-size: 12px; line-height: 1.4;">Securely verify your details online in minutes</div>
                                    </td>
                                    <td class="mobile-stack" style="width: 33.33%; vertical-align: top; text-align: center;">
                                        <div style="background-color: #eaf2f8; border: 1px solid #c4d7e6; color: #12344b; width: 52px; height: 52px; border-radius: 12px; margin: 0 auto 12px; line-height: 52px; font-size: 13px; font-weight: 700; letter-spacing: 0.7px;">VIP</div>
                                        <div style="font-weight: bold; color: #1f3443; margin-bottom: 8px; font-size: 14px;">Personalized services tailored to your stay</div>
                                        <div style="color: #666666; font-size: 12px; line-height: 1.4;">Share preferences early for a personalized stay</div>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>

                    <!-- Call to Action -->
                    <tr>
                        <td class="mobile-padding" style="padding: 12px 24px 18px 24px; text-align: center;">
                            <p style="margin: 0 0 13px 0; font-size: 15px; color: #495b68;">Simply click below to begin:</p>
                            <a href="${checkInUrl}"
                               style="display: inline-block; background-color: #12344b; color: #ffffff; text-decoration: none; padding: 13px 30px; border-radius: 8px; font-size: 15px; font-weight: 700;">
                                Start Check-in
                            </a>
                            <p style="margin: 10px 0 0 0; font-size: 12px; color: #666666;">Takes only 3-5 minutes to complete</p>
                        </td>
                    </tr>

                    <!-- Steps Section -->
                    <tr>
                        <td class="mobile-padding" style="padding: 18px 24px; background-color: #f8fafc;">
                            <p style="margin: 0 0 12px 0; font-size: 16px; color: #1f3443; font-weight: 700;">We'll guide you through these simple steps:</p>
                            <ol style="margin: 0; padding-left: 20px; color: #333333; line-height: 2;">
                                <li>Confirm your contact details.</li>
                                <li>Add additional guests (optional).</li>
                                <li>Share your estimated time of arrival.</li>
                                <li>Upload your ID/Passport.</li>
                                <li>Review hotel policies and sign digitally.</li>
                            </ol>
                        </td>
                    </tr>

                    <!-- Support -->
                    <tr>
                        <td class="mobile-padding" style="padding: 18px 24px;">
                            <p style="margin: 0; font-size: 14px; color: #666666; line-height: 1.6;">
                                If you have any questions or problems, do not hesitate to contact us or reply to this email.
                            </p>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f7fafc; padding: 20px; text-align: center; border-top: 1px solid #e1e8ef;">
                            <p style="margin: 0 0 10px 0; font-size: 14px; color: #666666;">
                                Need help? <a href="mailto:support@hotel.com" style="color: #12344b; text-decoration: none; font-weight: 700;">Contact us</a>
                            </p>
                            <p style="margin: 0; font-size: 12px; color: #999999;">
                                © ${new Date().getFullYear()} ${hotelName}. All rights reserved.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
  `;
}

// Send email function using Resend or SendGrid API
async function sendEmail({
  to,
  subject,
  html,
}: {
  to: string;
  subject: string;
  html: string;
}): Promise<boolean> {
  const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
  const RESEND_FROM_EMAIL = Deno.env.get("RESEND_FROM_EMAIL");
  const RESEND_FROM_NAME = Deno.env.get("RESEND_FROM_NAME") || "Petra Booking";

  const SENDGRID_API_KEY = Deno.env.get("SENDGRID_API_KEY");
  const SENDGRID_FROM_EMAIL = Deno.env.get("SENDGRID_FROM_EMAIL");
  const SENDGRID_FROM_NAME = Deno.env.get("SENDGRID_FROM_NAME") || "Petra Booking";

  // Validate email address
  if (!to || !to.includes("@")) {
    console.error(`❌ Invalid email address: ${to}`);
    throw new Error(`Invalid email address: ${to}`);
  }

  // Prefer Resend if configured, otherwise fallback to SendGrid
  if (RESEND_API_KEY && RESEND_FROM_EMAIL) {
    try {
      console.log(`📧 Sending email via Resend to: ${to}`);
      console.log(`   Subject: ${subject}`);
      console.log(`   From: ${RESEND_FROM_NAME} <${RESEND_FROM_EMAIL}>`);

      const response = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: `${RESEND_FROM_NAME} <${RESEND_FROM_EMAIL}>`,
          to: [to],
          subject,
          html,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`❌ Resend API error: ${response.status} - ${errorText}`);
        throw new Error(`Resend API error: ${response.status} - ${errorText}`);
      }

      const resendResponse = await response.json();
      console.log("✅ Email accepted by Resend");
      console.log(`   Resend ID: ${resendResponse?.id ?? "unknown"}`);
      console.log("   Note: accepted does not always mean delivered (check Resend logs/events).");
      return true;
    } catch (error) {
      console.error(`❌ Failed to send email via Resend: ${error.message}`);
      throw error;
    }
  }

  if (!SENDGRID_API_KEY || !SENDGRID_FROM_EMAIL) {
    console.warn("⚠️ No email provider configured (Resend/SendGrid). Email will be logged only.");
    console.log(`📧 [MOCK] Would send email to: ${to}`);
    console.log(`   Subject: ${subject}`);
    console.log(`   Type: ${html.includes("Booking Confirmed") ? "Confirmation" : "Reminder"}`);
    return false;
  }

  try {
    console.log(`📧 Sending email via SendGrid to: ${to}`);
    console.log(`   Subject: ${subject}`);
    console.log(`   From: ${SENDGRID_FROM_NAME} <${SENDGRID_FROM_EMAIL}>`);

    const response = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${SENDGRID_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: {
          name: SENDGRID_FROM_NAME,
          email: SENDGRID_FROM_EMAIL,
        },
        personalizations: [
          {
            to: [
              {
                email: to,
              },
            ],
          },
        ],
        subject: subject,
        content: [
          {
            type: "text/html",
            value: html,
          },
        ],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`❌ SendGrid API error: ${response.status} - ${errorText}`);
      throw new Error(`SendGrid API error: ${response.status} - ${errorText}`);
    }

    const sendgridMessageId = response.headers.get("x-message-id") || "not provided";
    console.log(`✅ Email accepted by SendGrid`);
    console.log(`   Status: ${response.status}`);
    console.log(`   Message ID: ${sendgridMessageId}`);
    console.log("   Note: accepted does not always mean delivered (check SendGrid activity).");
    return true;
  } catch (error) {
    console.error(`❌ Failed to send email via SendGrid: ${error.message}`);
    throw error;
  }
}
