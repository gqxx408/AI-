export interface StockQuote {
  code: string;
  name: string;
  currentPrice: number;
  openPrice: number;
  highPrice: number;
  lowPrice: number;
  previousClose: number;
  volume: number;
  amount: number;
  changePercent: number;
  lastUpdateTime: string;
  isUp: boolean;
}

export interface StockHistoryData {
  date: string;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
  amount: number;
}

export interface WatchlistStock {
  code: string;
  name: string;
  currentPrice: number;
  changePercent: number;
  isUp: boolean;
}
