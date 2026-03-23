// Email Template Service
// Generates HTML email templates for booking confirmations and check-in reminders

class EmailTemplateService {
  // Generate booking confirmation email HTML
  static String generateConfirmationEmail({
    required String guestName,
    required String hotelName,
    required String hotelAddress,
    required String hotelCity,
    required String hotelCountry,
    required String reservationNumber,
    required String checkInDate,
    required String checkOutDate,
    required String checkInTime,
    required String checkOutTime,
    required int numberOfGuests,
    required double totalAmount,
    required String checkInUrl, // URL to pre-arrival check-in website
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Confirmation</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #1e88e5 0%, #1565c0 100%); padding: 40px 20px; text-align: center; position: relative;">
                            <div style="color: #ffffff; font-size: 24px; font-weight: bold; margin-bottom: 10px;">Booking Confirmed!</div>
                            <div style="color: #ffffff; font-size: 16px;">Thank you for your reservation</div>
                        </td>
                    </tr>
                    
                    <!-- Greeting -->
                    <tr>
                        <td style="padding: 30px 20px 20px 20px;">
                            <p style="margin: 0; font-size: 16px; color: #333333;">Dear ${guestName},</p>
                            <p style="margin: 15px 0 0 0; font-size: 16px; color: #333333; line-height: 1.6;">
                                We are delighted to confirm your reservation at <strong>${hotelName}</strong>. 
                                Your booking has been successfully processed and payment received.
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Reservation Details Card -->
                    <tr>
                        <td style="padding: 0 20px 20px 20px;">
                            <div style="background-color: #f8f9fa; border-radius: 8px; padding: 20px; border: 1px solid #e0e0e0;">
                                <h2 style="margin: 0 0 20px 0; font-size: 20px; color: #1565c0; border-bottom: 2px solid #1565c0; padding-bottom: 10px;">
                                    Your Reservation Details
                                </h2>
                                
                                <table width="100%" cellpadding="10" cellspacing="0">
                                    <tr>
                                        <td style="width: 50%; vertical-align: top;">
                                            <div style="margin-bottom: 20px;">
                                                <div style="color: #666666; font-size: 12px; margin-bottom: 5px; display: flex; align-items: center;">
                                                    <span style="margin-right: 8px;">🏨</span> Hotel
                                                </div>
                                                <div style="color: #333333; font-size: 16px; font-weight: bold; margin-bottom: 5px;">
                                                    ${hotelName}
                                                </div>
                                                <div style="color: #666666; font-size: 14px; margin-bottom: 5px;">
                                                    ${hotelAddress}, ${hotelCity}, ${hotelCountry}
                                                </div>
                                                <a href="https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$hotelAddress, $hotelCity, $hotelCountry')}" 
                                                   style="color: #1e88e5; text-decoration: none; font-size: 14px;">
                                                    View on Map →
                                                </a>
                                            </div>
                                            
                                            <div style="margin-bottom: 20px;">
                                                <div style="color: #666666; font-size: 12px; margin-bottom: 5px; display: flex; align-items: center;">
                                                    <span style="margin-right: 8px;">#</span> Reservation Number
                                                </div>
                                                <div style="color: #333333; font-size: 18px; font-weight: bold;">
                                                    ${reservationNumber}
                                                </div>
                                            </div>
                                        </td>
                                        
                                        <td style="width: 50%; vertical-align: top;">
                                            <div style="margin-bottom: 20px;">
                                                <div style="color: #666666; font-size: 12px; margin-bottom: 5px; display: flex; align-items: center;">
                                                    <span style="margin-right: 8px;">📅</span> Check-in
                                                </div>
                                                <div style="color: #333333; font-size: 16px; font-weight: bold;">
                                                    ${checkInDate}
                                                </div>
                                                <div style="color: #666666; font-size: 14px;">
                                                    ${checkInTime}
                                                </div>
                                            </div>
                                            
                                            <div style="margin-bottom: 20px;">
                                                <div style="color: #666666; font-size: 12px; margin-bottom: 5px; display: flex; align-items: center;">
                                                    <span style="margin-right: 8px;">📅</span> Check-out
                                                </div>
                                                <div style="color: #333333; font-size: 16px; font-weight: bold;">
                                                    ${checkOutDate}
                                                </div>
                                                <div style="color: #666666; font-size: 14px;">
                                                    ${checkOutTime}
                                                </div>
                                            </div>
                                            
                                            <div>
                                                <div style="color: #666666; font-size: 12px; margin-bottom: 5px; display: flex; align-items: center;">
                                                    <span style="margin-right: 8px;">👥</span> Guests
                                                </div>
                                                <div style="color: #333333; font-size: 16px; font-weight: bold;">
                                                    ${numberOfGuests} ${numberOfGuests == 1 ? 'Guest' : 'Guests'}
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                    
                                    <tr>
                                        <td colspan="2" style="padding-top: 20px; border-top: 1px solid #e0e0e0;">
                                            <div style="text-align: right;">
                                                <div style="color: #666666; font-size: 12px; margin-bottom: 5px;">Total Amount</div>
                                                <div style="color: #4caf50; font-size: 24px; font-weight: bold;">
                                                    \$${totalAmount.toStringAsFixed(2)}
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                </table>
                            </div>
                        </td>
                    </tr>
                    
                    <!-- Call to Action -->
                    <tr>
                        <td style="padding: 20px; text-align: center;">
                            <p style="margin: 0 0 20px 0; font-size: 16px; color: #333333;">
                                We look forward to welcoming you!
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #e0e0e0;">
                            <p style="margin: 0 0 10px 0; font-size: 14px; color: #666666;">
                                Need help? <a href="mailto:support@hotel.com" style="color: #1e88e5; text-decoration: none;">Contact us</a>
                            </p>
                            <p style="margin: 0; font-size: 12px; color: #999999;">
                                This is an automated email. Please do not reply.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
''';
  }

  // Generate check-in reminder email HTML (48 hours before)
  static String generateCheckInReminderEmail({
    required String guestName,
    required String hotelName,
    required String hotelAddress,
    required String hotelCity,
    required String hotelCountry,
    required String reservationNumber,
    required String checkInDate,
    required String checkOutDate,
    required String checkInTime,
    required String checkOutTime,
    required String checkInUrl, // URL to pre-arrival check-in website
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Check-in Reminder</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #00bcd4 0%, #0097a7 100%); padding: 40px 20px; text-align: center; position: relative;">
                            <div style="color: #ffffff; font-size: 24px; font-weight: bold; margin-bottom: 10px;">
                                Your Stay Awaits - Begin Your Seamless Check-In
                            </div>
                        </td>
                    </tr>
                    
                    <!-- Greeting -->
                    <tr>
                        <td style="padding: 30px 20px 20px 20px;">
                            <p style="margin: 0; font-size: 16px; color: #333333;">Dear ${guestName},</p>
                            <p style="margin: 15px 0 0 0; font-size: 16px; color: #333333; line-height: 1.6;">
                                We are delighted to welcome you to <strong>${hotelName}</strong>. 
                                Below are your Reservation details.
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Reservation Details Card -->
                    <tr>
                        <td style="padding: 0 20px 20px 20px;">
                            <div style="background-color: #1e3a5f; border-radius: 8px; padding: 20px;">
                                <h2 style="margin: 0 0 20px 0; font-size: 20px; color: #ffffff; border-bottom: 2px solid #00bcd4; padding-bottom: 10px;">
                                    Your Reservation Details
                                </h2>
                                
                                <table width="100%" cellpadding="10" cellspacing="0">
                                    <tr>
                                        <td style="width: 50%; vertical-align: top;">
                                            <div style="margin-bottom: 20px;">
                                                <div style="color: #b0bec5; font-size: 12px; margin-bottom: 5px; display: flex; align-items: center;">
                                                    <span style="margin-right: 8px;">🏨</span> Hotel
                                                </div>
                                                <div style="color: #ffffff; font-size: 16px; font-weight: bold; margin-bottom: 5px;">
                                                    ${hotelName}
                                                </div>
                                                <div style="color: #b0bec5; font-size: 14px; margin-bottom: 5px;">
                                                    ${hotelAddress}, ${hotelCity}, ${hotelCountry}
                                                </div>
                                                <a href="https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$hotelAddress, $hotelCity, $hotelCountry')}" 
                                                   style="color: #00bcd4; text-decoration: none; font-size: 14px;">
                                                    View on Map →
                                                </a>
                                            </div>
                                            
                                            <div style="margin-bottom: 20px;">
                                                <div style="color: #b0bec5; font-size: 12px; margin-bottom: 5px; display: flex; align-items: center;">
                                                    <span style="margin-right: 8px;">#</span> Reservation Number
                                                </div>
                                                <div style="color: #ffffff; font-size: 18px; font-weight: bold;">
                                                    ${reservationNumber}
                                                </div>
                                            </div>
                                        </td>
                                        
                                        <td style="width: 50%; vertical-align: top;">
                                            <div style="margin-bottom: 20px;">
                                                <div style="color: #b0bec5; font-size: 12px; margin-bottom: 5px; display: flex; align-items: center;">
                                                    <span style="margin-right: 8px;">📅</span> Check-in
                                                </div>
                                                <div style="color: #ffffff; font-size: 16px; font-weight: bold;">
                                                    ${checkInDate}
                                                </div>
                                                <div style="color: #b0bec5; font-size: 14px;">
                                                    ${checkInTime}
                                                </div>
                                            </div>
                                            
                                            <div style="margin-bottom: 20px;">
                                                <div style="color: #b0bec5; font-size: 12px; margin-bottom: 5px; display: flex; align-items: center;">
                                                    <span style="margin-right: 8px;">📅</span> Check-out
                                                </div>
                                                <div style="color: #ffffff; font-size: 16px; font-weight: bold;">
                                                    ${checkOutDate}
                                                </div>
                                                <div style="color: #b0bec5; font-size: 14px;">
                                                    ${checkOutTime}
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                </table>
                            </div>
                        </td>
                    </tr>
                    
                    <!-- Benefits Section -->
                    <tr>
                        <td style="padding: 20px;">
                            <p style="margin: 0 0 20px 0; font-size: 16px; color: #333333; line-height: 1.6;">
                                To make your arrival effortless, we invite you to complete your check-in online before you arrive. This ensures:
                            </p>
                            
                            <table width="100%" cellpadding="15" cellspacing="0" style="margin-bottom: 20px;">
                                <tr>
                                    <td style="width: 33.33%; vertical-align: top; text-align: center;">
                                        <div style="background-color: #1e3a5f; width: 60px; height: 60px; border-radius: 50%; margin: 0 auto 15px; display: flex; align-items: center; justify-content: center;">
                                            <span style="font-size: 30px;">🚀</span>
                                        </div>
                                        <div style="font-weight: bold; color: #333333; margin-bottom: 8px; font-size: 14px;">
                                            A faster, contactless hotel arrival
                                        </div>
                                        <div style="color: #666666; font-size: 12px; line-height: 1.4;">
                                            Bypass the front desk and go directly to your room
                                        </div>
                                    </td>
                                    <td style="width: 33.33%; vertical-align: top; text-align: center;">
                                        <div style="background-color: #1e3a5f; width: 60px; height: 60px; border-radius: 50%; margin: 0 auto 15px; display: flex; align-items: center; justify-content: center;">
                                            <span style="font-size: 30px;">🆔</span>
                                        </div>
                                        <div style="font-weight: bold; color: #333333; margin-bottom: 8px; font-size: 14px;">
                                            Seamless and hassle-free ID verification
                                        </div>
                                        <div style="color: #666666; font-size: 12px; line-height: 1.4;">
                                            Securely verify your details online in minutes
                                        </div>
                                    </td>
                                    <td style="width: 33.33%; vertical-align: top; text-align: center;">
                                        <div style="background-color: #1e3a5f; width: 60px; height: 60px; border-radius: 50%; margin: 0 auto 15px; display: flex; align-items: center; justify-content: center;">
                                            <span style="font-size: 30px;">⭐</span>
                                        </div>
                                        <div style="font-weight: bold; color: #333333; margin-bottom: 8px; font-size: 14px;">
                                            Personalized services tailored to your stay
                                        </div>
                                        <div style="color: #666666; font-size: 12px; line-height: 1.4;">
                                            Share preferences early for a personalized stay
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    
                    <!-- Call to Action -->
                    <tr>
                        <td style="padding: 20px; text-align: center;">
                            <p style="margin: 0 0 15px 0; font-size: 16px; color: #333333;">
                                Simply click below to begin:
                            </p>
                            <a href="${checkInUrl}" 
                               style="display: inline-block; background: linear-gradient(135deg, #1e3a5f 0%, #1565c0 100%); color: #ffffff; text-decoration: none; padding: 15px 40px; border-radius: 5px; font-size: 16px; font-weight: bold; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                                Start Check-in
                            </a>
                            <p style="margin: 10px 0 0 0; font-size: 12px; color: #666666;">
                                Takes only 3-5 minutes to complete
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Steps Section -->
                    <tr>
                        <td style="padding: 20px; background-color: #f8f9fa;">
                            <p style="margin: 0 0 15px 0; font-size: 16px; color: #333333; font-weight: bold;">
                                We'll guide you through these simple steps:
                            </p>
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
                        <td style="padding: 20px;">
                            <p style="margin: 0; font-size: 14px; color: #666666; line-height: 1.6;">
                                If you have any questions or problems, do not hesitate to contact us or reply to this email.
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #e0e0e0;">
                            <p style="margin: 0 0 10px 0; font-size: 14px; color: #666666;">
                                Need help? <a href="mailto:support@hotel.com" style="color: #1e88e5; text-decoration: none;">Contact us</a>
                            </p>
                            <p style="margin: 0; font-size: 12px; color: #999999;">
                                This is an automated email. Please do not reply.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
''';
  }
}
