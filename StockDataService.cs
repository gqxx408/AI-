using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using AIStockTrader.WPF.Models;
using Newtonsoft.Json.Linq;

namespace AIStockTrader.WPF.Services
{
    public interface IStockDataService
    {
        Task<StockQuote?> GetRealTimeQuoteAsync(string stockCode);
        Task<List<StockHistoryData>> GetHistoryDataAsync(string stockCode, int days = 60);
        Task<List<WatchlistStock>> GetPopularStocksAsync();
    }

    public class EastMoneyStockDataService : IStockDataService
    {
        private readonly HttpClient _httpClient;

        public EastMoneyStockDataService()
        {
            var handler = new HttpClientHandler();
            handler.ServerCertificateCustomValidationCallback = (message, cert, chain, errors) => true;

            _httpClient = new HttpClient(handler);
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
            _httpClient.DefaultRequestHeaders.Add("Referer", "https://quote.eastmoney.com/");
            _httpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");
        }

        public async Task<StockQuote?> GetRealTimeQuoteAsync(string stockCode)
        {
            try
            {
                var secid = ConvertStockCodeToSecid(stockCode);
                var url = $"https://push2.eastmoney.com/api/qt/stock/get?secid={secid}&fields=f43,f44,f45,f46,f47,f48,f57,f58,f60,f169,f170,f171,f116,f117,f168,f167,f162,f163";

                System.Diagnostics.Debug.WriteLine($"[API请求] {stockCode} -> {url}");

                var response = await _httpClient.GetStringAsync(url);

                System.Diagnostics.Debug.WriteLine($"[API响应] {response.Substring(0, Math.Min(200, response.Length))}");

                var json = JObject.Parse(response);
                var data = json["data"];

                if (data == null)
                {
                    System.Diagnostics.Debug.WriteLine($"API返回数据为空");
                    return null;
                }

                var currentPrice = (data["f43"]?.ToObject<double>() ?? 0) / 100.0;
                var previousClose = (data["f60"]?.ToObject<double>() ?? 0) / 100.0;

                var quote = new StockQuote
                {
                    Code = data["f57"]?.ToString() ?? stockCode,
                    Name = data["f58"]?.ToString() ?? "",
                    CurrentPrice = currentPrice,
                    OpenPrice = (data["f46"]?.ToObject<double>() ?? 0) / 100.0,
                    HighPrice = (data["f44"]?.ToObject<double>() ?? 0) / 100.0,
                    LowPrice = (data["f45"]?.ToObject<double>() ?? 0) / 100.0,
                    PreviousClose = previousClose,
                    Volume = (data["f47"]?.ToObject<double>() ?? 0) / 100.0,
                    LastUpdateTime = DateTime.Now
                };

                quote.ChangePercent = previousClose > 0
                    ? ((quote.CurrentPrice - previousClose) / previousClose) * 100
                    : 0;

                return quote;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"获取实时行情失败: {ex.Message}");
                return null;
            }
        }

        public async Task<List<StockHistoryData>> GetHistoryDataAsync(string stockCode, int days = 60)
        {
            var historyData = new List<StockHistoryData>();

            try
            {
                var secid = ConvertStockCodeToSecid(stockCode);
                var endDate = DateTime.Now.ToString("yyyyMMdd");
                var startDate = DateTime.Now.AddDays(-days * 1.5).ToString("yyyyMMdd");
                var url = $"https://push2his.eastmoney.com/api/qt/stock/kline/get?secid={secid}&fields1=f1,f2,f3,f4,f5,f6&fields2=f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61&klt=101&fqt=1&beg={startDate}&end={endDate}&lmt={days}";

                var response = await _httpClient.GetStringAsync(url);
                var json = JObject.Parse(response);
                var klines = json["data"]?["klines"];

                if (klines != null)
                {
                    foreach (var kline in klines)
                    {
                        var parts = kline.ToString().Split(',');
                        if (parts.Length >= 6)
                        {
                            historyData.Add(new StockHistoryData
                            {
                                Date = DateTime.Parse(parts[0]),
                                Open = double.Parse(parts[1]),
                                Close = double.Parse(parts[2]),
                                High = double.Parse(parts[3]),
                                Low = double.Parse(parts[4]),
                                Volume = double.Parse(parts[5]),
                            });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"获取历史数据失败: {ex.Message}");
            }

            return historyData;
        }

        public async Task<List<WatchlistStock>> GetPopularStocksAsync()
        {
            var popularStocks = new List<WatchlistStock>
            {
                new WatchlistStock { Code = "sh600519", Name = "贵州茅台" },
                new WatchlistStock { Code = "sz000858", Name = "五粮液" },
                new WatchlistStock { Code = "sh601318", Name = "中国平安" },
                new WatchlistStock { Code = "sz000001", Name = "平安银行" },
                new WatchlistStock { Code = "sh600036", Name = "招商银行" },
                new WatchlistStock { Code = "sz300750", Name = "宁德时代" },
                new WatchlistStock { Code = "sh601012", Name = "隆基绿能" },
                new WatchlistStock { Code = "sz002594", Name = "比亚迪" },
                new WatchlistStock { Code = "sh688981", Name = "中芯国际" },
                new WatchlistStock { Code = "sz000651", Name = "格力电器" }
            };

            int successCount = 0;
            foreach (var stock in popularStocks)
            {
                try
                {
                    System.Diagnostics.Debug.WriteLine($"正在获取: {stock.Name} ({stock.Code})");
                    var quote = await GetRealTimeQuoteAsync(stock.Code);
                    if (quote != null && quote.CurrentPrice > 0)
                    {
                        stock.CurrentPrice = quote.CurrentPrice;
                        stock.ChangePercent = quote.ChangePercent;
                        successCount++;
                        System.Diagnostics.Debug.WriteLine($"成功: {stock.Name} = {quote.CurrentPrice}");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine($"失败: {stock.Name} 返回null");
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"异常: {stock.Name} - {ex.Message}");
                }
                await Task.Delay(100);
            }

            System.Diagnostics.Debug.WriteLine($"成功加载 {successCount}/{popularStocks.Count} 只股票");
            return popularStocks;
        }

        private string ConvertStockCodeToSecid(string stockCode)
        {
            if (stockCode.StartsWith("sh") || stockCode.StartsWith("6"))
            {
                var code = stockCode.Replace("sh", "");
                return $"1.{code}";
            }
            else if (stockCode.StartsWith("sz") || stockCode.StartsWith("0") || stockCode.StartsWith("3"))
            {
                var code = stockCode.Replace("sz", "");
                return $"0.{code}";
            }
            return $"1.{stockCode}";
        }
    }
}