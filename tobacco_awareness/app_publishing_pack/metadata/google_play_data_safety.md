# QuitMate - Google Play Data Safety Form Guide

গুগল প্লে কন্সোলের **App Content -> Data Safety** ফর্মে নিচের প্রশ্নগুলোর সঠিক উত্তর প্রদান করুন। এই ফর্মে ভুল উত্তর দিলে অ্যাপ প্রফাইল স্থগিত বা ব্যান হতে পারে।

---

## ১. প্রাথমিক প্রশ্নাবলী (Overview Questions)

1. **Does your app collect or share any of the required user data types?**
   - Answer: **Yes**

2. **Is all of the user data collected by your app encrypted in transit?**
   - Answer: **Yes** (All requests use HTTPS / SSL to our dedicated backend server)

3. **Do you provide a way for users to request that their data be deleted?**
   - Answer: **Yes** (Users can request account & data deletion via in-app request or emailing `ariful010a@gmail.com`)

---

## ২. সংগ্রহকৃত ডেটা নির্বাচন (Data Types Collected)

### A. Personal Info (ব্যক্তিগত তথ্য)
- **Name**: Collected for account profile & peer support chat display. (Optional/Required: Required, Ephemeral: No, Processed & Stored: Yes).
- **Email address**: Collected via Firebase Auth (Google Sign-In) for user authentication & account security.

### B. Health and Fitness (স্বাস্থ্য তথ্য)
- **Health information**: Collected for smoking cessation progress, quit date, craving logs, daily check-in health status.

### C. Financial Info (অর্থ সংক্রান্ত তথ্য)
- **Other financial info**: Collected purely as a user-entered number (Money Saver wishlist and daily saved amount tracking). *Note: No real financial transactions, credit cards, or bank details are collected.*

### D. Messages (মেসেজ)
- **Other in-app messages**: Collected for Peer Support Group Chat messages sent by users.

### E. Photos and Videos (ছবি)
- **Photos**: Collected if users choose to upload a profile picture or share an image in the support group chat.

---

## ৩. ডেটা ব্যবহার ও কারণ (Data Usage Reasons)

প্রতিটি ডেটার ক্ষেত্রে ফর্মে ব্যবহারের কারণ হিসেবে নির্বাচন করুন:
- **App functionality** (অ্যাপের মূল কার্যক্রম পরিচালনার জন্য)
- **Account management** (ব্যবহারকারীর অ্যাকাউন্ট ব্যবস্থাপনার জন্য)

---

## ৪. ডেটা শেয়ারিং (Data Sharing)

- **Does your app share user data with third parties?**
  - Answer: **No** (We do not sell or share data with advertisers or third parties. Data is only processed on our own secure backend server).
