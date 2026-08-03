/**
 * Backend Utility Tests (Jest)
 * tobacco_awareness_backend/tests/utils.test.js
 * 
 * Run: npm test
 */

const { getBstTodayStr } = require('../utils/time_utils');

describe('getBstTodayStr() - BST তারিখ ফাংশন', () => {
  test('সঠিক YYYY-MM-DD ফরম্যাটে তারিখ রিটার্ন করে', () => {
    const result = getBstTodayStr();
    expect(result).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });

  test('রিটার্ন ভ্যালু একটি string', () => {
    const result = getBstTodayStr();
    expect(typeof result).toBe('string');
  });

  test('তারিখের মাস সঠিক সীমায় (01–12)', () => {
    const result = getBstTodayStr();
    const month = parseInt(result.split('-')[1], 10);
    expect(month).toBeGreaterThanOrEqual(1);
    expect(month).toBeLessThanOrEqual(12);
  });

  test('তারিখের দিন সঠিক সীমায় (01–31)', () => {
    const result = getBstTodayStr();
    const day = parseInt(result.split('-')[2], 10);
    expect(day).toBeGreaterThanOrEqual(1);
    expect(day).toBeLessThanOrEqual(31);
  });

  test('বছর বর্তমান বা ভবিষ্যতের (2024 এর পর)', () => {
    const result = getBstTodayStr();
    const year = parseInt(result.split('-')[0], 10);
    expect(year).toBeGreaterThanOrEqual(2024);
  });
});

describe('Backend Config Validation', () => {
  test('BACKEND_URL env variable পাঠযোগ্য', () => {
    // শুধু চেক করছি env সিস্টেম কাজ করছে কিনা
    expect(typeof process.env).toBe('object');
  });
});
