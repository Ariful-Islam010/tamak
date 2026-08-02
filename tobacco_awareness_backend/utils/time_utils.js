function getBstTodayStr() {
  const d = new Date();
  // UTC+6 offset in ms
  const bstDate = new Date(d.getTime() + (6 * 60 * 60 * 1000) + (d.getTimezoneOffset() * 60 * 1000));
  const year = bstDate.getFullYear();
  const month = String(bstDate.getMonth() + 1).padStart(2, '0');
  const day = String(bstDate.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

module.exports = { getBstTodayStr };
