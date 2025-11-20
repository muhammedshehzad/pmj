# Payment Links Feature Setup Guide

## Overview
This feature allows admins to send UPI payment links to donors via WhatsApp or SMS. When donors click the link, it opens their UPI app (Google Pay, PhonePe, etc.) with the payment amount pre-filled.

## Setup Instructions

### 1. Configure UPI Details
1. Open the app and go to **Settings**
2. Tap on **"UPI Configuration"**
3. Enter your UPI ID (e.g., `yourname@paytm`, `yourname@phonepe`)
4. Enter your organization name (e.g., "PMJ Donations")
5. Save the configuration

### 2. Ensure Donor Phone Numbers
- Make sure all donors have phone numbers stored in their profiles
- Phone numbers should be in the format: `9876543210` (without country code)
- The app will automatically add the India country code (+91)

### 3. Send Payment Links
1. Go to **Settings** → **"Send Payment Links"**
2. Select the donors you want to send links to
3. Customize the message template if needed
4. Choose to send via:
   - **WhatsApp**: Opens WhatsApp with pre-filled message (requires manual send)
   - **SMS**: Opens SMS app with pre-filled message (requires manual send)

## How It Works

### For Admins:
1. Select donors from the list
2. The app generates UPI payment links with the donor's amount
3. WhatsApp/SMS opens with a message containing the payment link
4. Admin taps "Send" to deliver the message

### For Donors:
1. Receive WhatsApp/SMS message with payment link
2. Tap the UPI link in the message
3. Their UPI app (Google Pay, PhonePe, etc.) opens automatically
4. Payment amount is pre-filled
5. Complete the payment in their UPI app

## Message Template
You can customize the message template using these placeholders:
- `{name}` - Donor's name
- `{amount}` - Payment amount with ₹ symbol
- `{upi_link}` - The actual UPI payment link

Default template:
```
Dear {name},

Please pay your monthly donation of {amount} using this link:

{upi_link}

Thank you for your continued support!

- PMJ Team
```

## Testing
1. Use the **"Test UPI Link (₹1)"** button to verify your UPI configuration
2. This will open your UPI app with a ₹1 test payment
3. You don't need to complete the payment, just verify it opens correctly

## Important Notes

### Security & Compliance
- UPI links are secure and standard across all UPI apps
- No sensitive information is stored in the links
- Each payment gets a unique transaction reference ID

### Limitations
- WhatsApp/SMS requires manual sending (admin must tap "Send")
- Phone numbers must be stored for each donor
- Internet connection required for sending messages
- UPI apps must be installed on donor's phone

### Troubleshooting
- **"Could not launch WhatsApp"**: WhatsApp not installed or phone number invalid
- **"Phone number not available"**: Add phone numbers to donor profiles
- **"Could not launch UPI app"**: No UPI apps installed or UPI ID incorrect
- **Payment not received**: Ask donor to share UPI transaction ID for verification

## Supported UPI Apps
- Google Pay
- PhonePe
- Paytm
- BHIM
- Amazon Pay
- Any other UPI-enabled app

## Best Practices
1. Test your UPI configuration before sending to donors
2. Keep messages short and clear
3. Include your organization name for trust
4. Ask donors to reply with transaction ID after payment
5. Send payment links at the beginning of each month
6. Follow up with donors who haven't paid

## Technical Details
- Uses standard UPI deep-link format: `upi://pay?pa=...&pn=...&am=...`
- Compatible with all UPI apps in India
- Generates unique transaction reference for each payment
- Stores UPI configuration locally using SharedPreferences