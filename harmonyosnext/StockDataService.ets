import http from '@ohos.net.http';
import { StockQuote, StockHistoryData, WatchlistStock } from '../models/StockModels';

interface StockApiResponse {
  data: {
    f43?: number;
    f44?: number;
    f45?: number;
    f46?: number;
    f47?: number;
    f48?: number;
    f57?: string;
    f58?: string;
    f60?: number;
    klines?: string[];
  };
}

export class StockDataService {
  private baseUrl: string = 'https://push2.eastmoney.com';
  
  convertStockCodeToSecid(stockCode: string): string {
    if (stockCode.startsWith('sh') || stockCode.startsWith('6')) {
      let code = stockCode.replace('sh', '');
      return `1.${code}`;
    } else if (stockCode.startsWith('sz') || stockCode.startsWith('0') || stockCode.startsWith('3')) {
      let code = stockCode.replace('sz', '');
      return `0.${code}`;
    } else if (stockCode.startsWith('bj') || stockCode.startsWith('8') || stockCode.startsWith('4')) {
      let code = stockCode.replace('bj', '');
      return `0.${code}`;
    }
    return `1.${stockCode}`;
  }
  
  async getRealTimeQuote(stockCode: string): Promise<StockQuote | null> {
    try {
      let secid = this.convertStockCodeToSecid(stockCode);
      let url = `${this.baseUrl}/api/qt/stock/get?secid=${secid}&fields=f43,f44,f45,f46,f47,f48,f57,f58,f60,f169,f170,f171,f116,f117,f168,f167,f162,f163`;
      
      let response = await this.fetchData(url);
      if (!response || !response.data) {
        return null;
      }
      
      let data = response.data;
      let currentPrice = (data.f43 ?? 0) / 100.0;
      let previousClose = (data.f60 ?? 0) / 100.0;
      
      let changePercent = previousClose > 0
        ? ((currentPrice - previousClose) / previousClose) * 100
        : 0;
      
      let now = new Date();
      let timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
      
      let quote: StockQuote = {
        code: data.f57 ?? stockCode,
        name: data.f58 ?? '',
        currentPrice: currentPrice,
        openPrice: (data.f46 ?? 0) / 100.0,
        highPrice: (data.f44 ?? 0) / 100.0,
        lowPrice: (data.f45 ?? 0) / 100.0,
        previousClose: previousClose,
        volume: (data.f47 ?? 0) / 100.0,
        amount: (data.f48 ?? 0) / 100.0,
        changePercent: changePercent,
        lastUpdateTime: timeStr,
        isUp: changePercent > 0
      };
      
      return quote;
    } catch (error) {
      console.error(`获取实时行情失败: ${JSON.stringify(error)}`);
      return null;
    }
  }
  
  async getHistoryData(stockCode: string, days: number = 60): Promise<StockHistoryData[]> {
    let historyData: StockHistoryData[] = [];
    
    try {
      let secid = this.convertStockCodeToSecid(stockCode);
      let now = new Date();
      let endDate = `${now.getFullYear()}${(now.getMonth() + 1).toString().padStart(2, '0')}${now.getDate().toString().padStart(2, '0')}`;
      
      let startDate = new Date(now.getTime() - days * 2 * 24 * 60 * 60 * 1000);
      let startDateStr = `${startDate.getFullYear()}${(startDate.getMonth() + 1).toString().padStart(2, '0')}${startDate.getDate().toString().padStart(2, '0')}`;
      
      let url = `${this.baseUrl}/api/qt/stock/kline/get?secid=${secid}&fields1=f1,f2,f3,f4,f5,f6&fields2=f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61&klt=101&fqt=1&beg=${startDateStr}&end=${endDate}&lmt=${days}`;
      
      let response = await this.fetchData(url);
      if (response && response.data && response.data.klines) {
        let klines = response.data.klines as string[];
        for (let kline of klines) {
          let parts = kline.split(',');
          if (parts.length >= 6) {
            let history: StockHistoryData = {
              date: parts[0],
              open: parseFloat(parts[1]),
              close: parseFloat(parts[2]),
              high: parseFloat(parts[3]),
              low: parseFloat(parts[4]),
              volume: parseFloat(parts[5]),
              amount: parseFloat(parts[6] ?? '0')
            };
            historyData.push(history);
          }
        }
      }
    } catch (error) {
      console.error(`获取历史数据失败: ${JSON.stringify(error)}`);
    }
    
    return historyData;
  }
  
  async getPopularStocks(): Promise<WatchlistStock[]> {
    let popularStocks: WatchlistStock[] = [
      { code: 'sh600519', name: '贵州茅台', currentPrice: 0, changePercent: 0, isUp: true },
      { code: 'sz000858', name: '五粮液', currentPrice: 0, changePercent: 0, isUp: true },
      { code: 'sh601318', name: '中国平安', currentPrice: 0, changePercent: 0, isUp: true },
      { code: 'sz000001', name: '平安银行', currentPrice: 0, changePercent: 0, isUp: true },
      { code: 'sh600036', name: '招商银行', currentPrice: 0, changePercent: 0, isUp: true },
      { code: 'sz300750', name: '宁德时代', currentPrice: 0, changePercent: 0, isUp: true },
      { code: 'sh601012', name: '隆基绿能', currentPrice: 0, changePercent: 0, isUp: true },
      { code: 'sz002594', name: '比亚迪', currentPrice: 0, changePercent: 0, isUp: true },
      { code: 'sh688981', name: '中芯国际', currentPrice: 0, changePercent: 0, isUp: true },
      { code: 'sz000651', name: '格力电器', currentPrice: 0, changePercent: 0, isUp: true }
    ];
    
    for (let stock of popularStocks) {
      try {
        let quote = await this.getRealTimeQuote(stock.code);
        if (quote) {
          stock.currentPrice = quote.currentPrice;
          stock.changePercent = quote.changePercent;
          stock.isUp = quote.isUp;
        }
      } catch (error) {
        // skip on error
      }
    }
    
    return popularStocks;
  }
  
  private async fetchData(url: string): Promise<StockApiResponse> {
    return new Promise((resolve: (value: StockApiResponse) => void, reject: (reason: Error) => void) => {
      let httpRequest: http.HttpRequest = http.createHttp();
      httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Referer': 'https://quote.eastmoney.com/',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        connectTimeout: 10000,
        readTimeout: 10000
      }, (err: Error, data: http.HttpResponse) => {
        httpRequest.destroy();
        if (!err) {
          try {
            let result: StockApiResponse = JSON.parse(data.result as string);
            resolve(result);
          } catch (e) {
            reject(e as Error);
          }
        } else {
          reject(err);
        }
      });
    });
  }
}
