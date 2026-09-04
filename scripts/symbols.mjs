// Taranacak BIST evreni. Tek kaynak: hem script hem (ileride) uygulama bunu okur.
// Likit büyükler + BIST 100'ün çoğu. Genişletmek için sadece koda ekleyin.

export const BIST_UNIVERSE = [
  'ASELS', 'THYAO', 'TUPRS', 'BIMAS', 'KCHOL', 'SAHOL', 'FROTO', 'TOASO',
  'SISE', 'EREGL', 'KRDMD', 'PETKM', 'OYAKC', 'TCELL', 'PGSUS', 'AEFES',
  'CCOLA', 'MGROS', 'ULKER', 'TAVHL', 'ENKAI', 'SASA', 'ALARK', 'HEKTS',
  'GUBRF', 'VESTL', 'ARCLK', 'TKFEN', 'DOAS', 'ISDMR', 'YKBNK', 'AKBNK',
  'GARAN', 'ISCTR', 'HALKB', 'VAKBN', 'TTKOM', 'BRSAN', 'KONTR', 'SMRTG',
  'ODAS', 'ENJSA', 'AKSEN', 'ZOREN', 'CIMSA', 'AGHOL', 'BUCIM', 'OTKAR',
  'KARSN', 'TTRAK', 'EKGYO', 'ISGYO', 'TSKB', 'ALBRK', 'SKBNK', 'MPARK',
  'LKMNH', 'SELEC', 'BAGFS', 'KOZAL', 'KOZAA', 'IPEKE', 'GLYHO', 'MAVI',
];

export const INDEX_SYMBOL = 'XU100.IS';

// Katılım Endeksi'ne uygun (faizsiz) hisseler — uygulamadaki liste ile aynı olmalı.
export const PARTICIPATION = new Set([
  'ASELS', 'BIMAS', 'FROTO', 'TOASO', 'TUPRS', 'EREGL', 'KRDMD', 'PETKM',
  'SASA', 'HEKTS', 'GUBRF', 'BAGFS', 'CIMSA', 'BUCIM', 'OYAKC', 'ENKAI',
  'TKFEN', 'OTKAR', 'TTRAK', 'KONTR', 'SMRTG', 'ODAS', 'AKSEN', 'ZOREN',
  'MGROS', 'ULKER', 'CCOLA', 'AEFES', 'SELEC', 'MPARK', 'LKMNH', 'MAVI',
]);
