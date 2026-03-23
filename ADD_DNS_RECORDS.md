# Add DNS Records for petrabooking.com

## Records to Add

You need to add these DNS records to your domain registrar (where you manage `petrabooking.com`):

---

## 1. DKIM Record (Required)

**Type**: `TXT`  
**Name**: `resend._domainkey`  
**Content**: (Copy the full value from Resend - starts with `p=MIGfMA...`)  
**TTL**: `Auto` or `3600`

**How to add**:
- Go to your domain's DNS management
- Add a new TXT record
- Name: `resend._domainkey`
- Value: (paste the full content from Resend)
- Save

---

## 2. SPF Records (Required)

### Record 1: MX Record
**Type**: `MX`  
**Name**: `Resend` (or `@` or leave blank, depending on your DNS provider)  
**Content**: (Copy from Resend - contains `feedback...ses.com`)  
**Priority**: `10`  
**TTL**: `Auto` or `3600`

### Record 2: TXT Record
**Type**: `TXT`  
**Name**: `Resend` (or `@` or leave blank, depending on your DNS provider)  
**Content**: (Copy from Resend - starts with `v=spf1 i...om ~all`)  
**TTL**: `Auto` or `3600`

**How to add**:
- Add MX record with priority 10
- Add TXT record with SPF content
- Save both

---

## 3. DMARC Record (Optional but Recommended)

**Type**: `TXT`  
**Name**: `_dmarc`  
**Content**: `v=DMARC1; p=none;`  
**TTL**: `Auto` or `3600`

**How to add**:
- Add a new TXT record
- Name: `_dmarc`
- Value: `v=DMARC1; p=none;`
- Save

---

## Where to Add These Records

### Common DNS Providers:

1. **GoDaddy**:
   - Go to "DNS Management"
   - Click "Add" for each record
   - Select type, enter name and value

2. **Namecheap**:
   - Go to "Advanced DNS"
   - Click "Add New Record"
   - Select type, enter host and value

3. **Cloudflare**:
   - Go to DNS → Records
   - Click "Add record"
   - Select type, enter name and content

4. **Google Domains**:
   - Go to "DNS"
   - Click "Custom records"
   - Add each record

5. **AWS Route 53**:
   - Go to "Hosted zones"
   - Click "Create record"
   - Add each record

---

## Important Notes

1. **Name Field**:
   - Some providers use `@` for root domain
   - Some use blank/empty for root domain
   - Some use the full domain name
   - Check your provider's documentation

2. **TTL**:
   - Use `Auto` if available
   - Or set to `3600` (1 hour)
   - Lower TTL = faster updates but more DNS queries

3. **Wait for Propagation**:
   - DNS changes can take 5-60 minutes
   - Sometimes up to 24 hours
   - Resend will check automatically

---

## After Adding Records

1. **Go back to Resend Dashboard** → **Domains**
2. **Check Verification Status**:
   - Resend will automatically check DNS records
   - Should show "Verified" with green checkmark
   - If not verified, wait 10-30 minutes and refresh

3. **Enable Sending** (if not already enabled):
   - Make sure the toggle is ON (green)
   - This allows sending emails from this domain

---

## Verify Records Are Added

You can check if records are added using online DNS lookup tools:

1. **MXToolbox**: https://mxtoolbox.com/
   - Enter `petrabooking.com`
   - Check TXT records
   - Look for `resend._domainkey` and SPF records

2. **DNS Checker**: https://dnschecker.org/
   - Enter record name and type
   - Check if it's propagated globally

---

## Troubleshooting

### Records Not Showing in Resend?

1. **Wait 10-30 minutes** - DNS propagation takes time
2. **Check for typos** - Copy-paste values exactly
3. **Verify record type** - Must be TXT for DKIM/SPF/DMARC
4. **Check name format** - Some providers need `@` or blank

### Still Not Verified After 1 Hour?

1. **Double-check all records** are added correctly
2. **Verify record values** match exactly (no extra spaces)
3. **Check DNS provider** - Some have delays
4. **Contact Resend support** if still not working

---

## Next Step After Verification

Once domain shows "Verified" in Resend:

1. **Update Supabase Edge Function**:
   - Go to Supabase Dashboard → Edge Functions → checkin-reminder → Settings
   - Update `RESEND_FROM_EMAIL` to: `noreply@petrabooking.com`
   - Save

2. **Test Email Sending**:
   - Create a new booking
   - Complete payment
   - Check if email is received

---

## Quick Checklist

- [ ] Added DKIM TXT record (`resend._domainkey`)
- [ ] Added SPF MX record (priority 10)
- [ ] Added SPF TXT record
- [ ] Added DMARC TXT record (`_dmarc`) - optional
- [ ] Waited 10-30 minutes for DNS propagation
- [ ] Checked Resend Dashboard - domain shows "Verified"
- [ ] Enabled sending (toggle is ON)
- [ ] Updated `RESEND_FROM_EMAIL` in Supabase to `@petrabooking.com`
- [ ] Tested with a new booking
