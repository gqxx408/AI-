using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using AIStockTrader.WPF.Models;

namespace AIStockTrader.WPF.Services
{
    public interface IAIAnalysisService
    {
        Task<StockAnalysis> AnalyzeStockAsync(StockQuote quote, List<StockHistoryData> historyData);
    }

    public class AIAnalysisService : IAIAnalysisService
    {
        public async Task<StockAnalysis> AnalyzeStockAsync(StockQuote quote, List<StockHistoryData> historyData)
        {
            return await Task.Run(() =>
            {
                var analysis = new StockAnalysis
                {
                    StockCode = quote.Code,
                    StockName = quote.Name,
                    AnalysisTime = DateTime.Now
                };

                if (historyData.Count < 20)
                {
                    analysis.Reason = "历史数据不足，无法进行完整分析";
                    analysis.Score = 50;
                    return analysis;
                }

                CalculateTechnicalIndicators(historyData, analysis);
                double mlScore = CalculateMLScore(analysis, historyData);
                
                analysis.Score = NormalizeScore(mlScore);
                analysis.Recommendation = GetRecommendation(analysis.Score);
                analysis.Reason = GenerateReason(analysis);
                analysis.Confidence = CalculateConfidence(analysis, historyData);

                return analysis;
            });
        }

        private void CalculateTechnicalIndicators(List<StockHistoryData> historyData, StockAnalysis analysis)
        {
            var closes = historyData.Select(h => h.Close).ToList();
            var highs = historyData.Select(h => h.High).ToList();
            var lows = historyData.Select(h => h.Low).ToList();

            analysis.MA5 = CalculateMA(closes, 5);
            analysis.MA20 = CalculateMA(closes, 20);
            CalculateMACD(closes, analysis);
            CalculateRSI(closes, analysis);
            CalculateKDJ(highs, lows, closes, analysis);
        }

        private double CalculateMA(List<double> prices, int period)
        {
            if (prices.Count < period) return prices.LastOrDefault();
            return prices.Skip(prices.Count - period).Average();
        }

        private void CalculateMACD(List<double> closes, StockAnalysis analysis)
        {
            var ema12 = CalculateEMA(closes, 12);
            var ema26 = CalculateEMA(closes, 26);
            analysis.MACDValue = ema12 - ema26;
        }

        private double CalculateEMA(List<double> prices, int period)
        {
            if (prices.Count == 0) return 0;
            if (prices.Count < period) return prices.Average();

            double multiplier = 2.0 / (period + 1);
            double ema = prices.Take(period).Average();

            for (int i = period; i < prices.Count; i++)
            {
                ema = (prices[i] - ema) * multiplier + ema;
            }

            return ema;
        }

        private void CalculateRSI(List<double> closes, StockAnalysis analysis, int period = 14)
        {
            if (closes.Count < period + 1)
            {
                analysis.RSIValue = 50;
                return;
            }

            double gainSum = 0;
            double lossSum = 0;

            for (int i = closes.Count - period; i < closes.Count; i++)
            {
                double change = closes[i] - closes[i - 1];
                if (change > 0) gainSum += change;
                else lossSum += Math.Abs(change);
            }

            double avgGain = gainSum / period;
            double avgLoss = lossSum / period;

            if (avgLoss == 0)
            {
                analysis.RSIValue = 100;
            }
            else
            {
                double rs = avgGain / avgLoss;
                analysis.RSIValue = 100 - (100 / (1 + rs));
            }
        }

        private void CalculateKDJ(List<double> highs, List<double> lows, List<double> closes, StockAnalysis analysis, int period = 9)
        {
            if (closes.Count < period)
            {
                analysis.KDJ_K = 50;
                analysis.KDJ_D = 50;
                analysis.KDJ_J = 50;
                return;
            }

            var recentHighs = highs.TakeLast(period).ToList();
            var recentLows = lows.TakeLast(period).ToList();
            double highestHigh = recentHighs.Max();
            double lowestLow = recentLows.Min();

            double rsv = (highestHigh == lowestLow) ? 50 : ((closes.Last() - lowestLow) / (highestHigh - lowestLow)) * 100;

            analysis.KDJ_K = (2.0 / 3) * 50 + (1.0 / 3) * rsv;
            analysis.KDJ_D = (2.0 / 3) * 50 + (1.0 / 3) * analysis.KDJ_K;
            analysis.KDJ_J = 3 * analysis.KDJ_K - 2 * analysis.KDJ_D;
        }

        private double CalculateMLScore(StockAnalysis analysis, List<StockHistoryData> historyData)
        {
            double score = 50;
            double currentPrice = historyData.LastOrDefault()?.Close ?? 0;

            if (currentPrice > analysis.MA5) score += 5;
            if (currentPrice > analysis.MA20) score += 5;
            if (analysis.MA5 > analysis.MA20) score += 10;

            if (analysis.MACDValue > 0) score += 8;
            else if (analysis.MACDValue < 0) score -= 8;

            if (analysis.RSIValue < 30) score += 12;
            else if (analysis.RSIValue > 70) score -= 12;

            if (analysis.KDJ_J < 20) score += 10;
            else if (analysis.KDJ_J > 80) score -= 10;

            return score;
        }

        private double NormalizeScore(double rawScore)
        {
            return Math.Max(0, Math.Min(100, rawScore));
        }

        private RecommendationType GetRecommendation(double score)
        {
            if (score >= 75) return RecommendationType.StrongBuy;
            if (score >= 60) return RecommendationType.Buy;
            if (score >= 40) return RecommendationType.Hold;
            if (score >= 25) return RecommendationType.Sell;
            return RecommendationType.StrongSell;
        }

        private string GenerateReason(StockAnalysis analysis)
        {
            var reasons = new List<string>();

            if (analysis.MA5 > analysis.MA20)
                reasons.Add("均线呈多头排列，趋势向好");
            else if (analysis.MA5 < analysis.MA20)
                reasons.Add("均线呈空头排列，趋势走弱");

            if (analysis.MACDValue > 0)
                reasons.Add("MACD指标显示买入信号");
            else if (analysis.MACDValue < 0)
                reasons.Add("MACD指标显示卖出信号");

            if (analysis.RSIValue < 30)
                reasons.Add("RSI指标显示超卖，可能存在反弹机会");
            else if (analysis.RSIValue > 70)
                reasons.Add("RSI指标显示超买，注意回调风险");

            if (reasons.Count == 0)
                reasons.Add("各项指标显示市场处于震荡整理状态");

            return string.Join("；", reasons);
        }

        private double CalculateConfidence(StockAnalysis analysis, List<StockHistoryData> historyData)
        {
            double confidence = 60;

            if (historyData.Count >= 60) confidence += 15;
            else if (historyData.Count >= 30) confidence += 10;

            return Math.Min(95, Math.Max(40, confidence));
        }
    }
}
