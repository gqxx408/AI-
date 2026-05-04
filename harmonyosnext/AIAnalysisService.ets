import { StockQuote, StockHistoryData } from '../models/StockModels';

export interface StockAnalysis {
  stockCode: string;
  stockName: string;
  analysisTime: string;
  score: number;
  recommendation: RecommendationType;
  recommendationText: string;
  reason: string;
  macdValue: number;
  rsiValue: number;
  kdjK: number;
  kdjD: number;
  kdjJ: number;
  ma5: number;
  ma10: number;
  ma20: number;
  ma60: number;
  bollUpper: number;
  bollMiddle: number;
  bollLower: number;
  confidence: number;
  scoreColor: string;
}

export enum RecommendationType {
  StrongBuy,
  Buy,
  Hold,
  Sell,
  StrongSell
}

export class AIAnalysisService {
  async analyzeStock(quote: StockQuote, historyData: StockHistoryData[]): Promise<StockAnalysis> {
    let analysis: StockAnalysis = {
      stockCode: quote.code,
      stockName: quote.name,
      analysisTime: this.getCurrentTime(),
      score: 50,
      recommendation: RecommendationType.Hold,
      recommendationText: '持有观望',
      reason: '',
      macdValue: 0,
      rsiValue: 50,
      kdjK: 50,
      kdjD: 50,
      kdjJ: 50,
      ma5: 0,
      ma10: 0,
      ma20: 0,
      ma60: 0,
      bollUpper: 0,
      bollMiddle: 0,
      bollLower: 0,
      confidence: 50,
      scoreColor: '#FFAA00'
    };

    if (historyData.length < 20) {
      analysis.reason = '历史数据不足，无法进行完整分析';
      analysis.score = 50;
      return analysis;
    }

    this.calculateTechnicalIndicators(historyData, analysis);
    let mlScore = this.calculateMLScore(analysis, historyData);
    analysis.score = this.normalizeScore(mlScore);
    analysis.recommendation = this.getRecommendation(analysis.score);
    analysis.recommendationText = this.getRecommendationText(analysis.recommendation);
    analysis.reason = this.generateReason(analysis);
    analysis.confidence = this.calculateConfidence(analysis, historyData);
    analysis.scoreColor = this.getScoreColor(analysis.score);

    return analysis;
  }

  private calculateTechnicalIndicators(historyData: StockHistoryData[], analysis: StockAnalysis): void {
    let closes: number[] = historyData.map(h => h.close);
    let highs: number[] = historyData.map(h => h.high);
    let lows: number[] = historyData.map(h => h.low);

    analysis.ma5 = this.calculateMA(closes, 5);
    analysis.ma10 = this.calculateMA(closes, 10);
    analysis.ma20 = this.calculateMA(closes, 20);
    analysis.ma60 = historyData.length >= 60 ? this.calculateMA(closes, 60) : analysis.ma20;

    this.calculateMACD(closes, analysis);
    this.calculateRSI(closes, analysis);
    this.calculateKDJ(highs, lows, closes, analysis);
    this.calculateBollingerBands(closes, analysis);
  }

  private calculateMA(prices: number[], period: number): number {
    if (prices.length < period) {
      return prices[prices.length - 1];
    }
    let sum = 0;
    for (let i = prices.length - period; i < prices.length; i++) {
      sum += prices[i];
    }
    return sum / period;
  }

  private calculateMACD(closes: number[], analysis: StockAnalysis): void {
    let ema12 = this.calculateEMA(closes, 12);
    let ema26 = this.calculateEMA(closes, 26);
    let dif = ema12 - ema26;

    let difList: number[] = [];
    for (let i = 1; i <= closes.length; i++) {
      let slice = closes.slice(0, i);
      let e12 = this.calculateEMA(slice, 12);
      let e26 = this.calculateEMA(slice, 26);
      difList.push(e12 - e26);
    }

    if (difList.length >= 9) {
      let dea = this.calculateEMA(difList, 9);
      analysis.macdValue = (difList[difList.length - 1] - dea) * 2;
    } else {
      analysis.macdValue = dif;
    }
  }

  private calculateEMA(prices: number[], period: number): number {
    if (prices.length === 0) return 0;
    if (prices.length < period) {
      let sum = 0;
      for (let p of prices) {
        sum += p;
      }
      return sum / prices.length;
    }

    let multiplier = 2.0 / (period + 1);
    let sum = 0;
    for (let i = 0; i < period; i++) {
      sum += prices[i];
    }
    let ema = sum / period;

    for (let i = period; i < prices.length; i++) {
      ema = (prices[i] - ema) * multiplier + ema;
    }

    return ema;
  }

  private calculateRSI(closes: number[], analysis: StockAnalysis, period: number = 14): void {
    if (closes.length < period + 1) {
      analysis.rsiValue = 50;
      return;
    }

    let gainSum = 0;
    let lossSum = 0;

    for (let i = closes.length - period; i < closes.length; i++) {
      let change = closes[i] - closes[i - 1];
      if (change > 0) {
        gainSum += change;
      } else {
        lossSum += Math.abs(change);
      }
    }

    let avgGain = gainSum / period;
    let avgLoss = lossSum / period;

    if (avgLoss === 0) {
      analysis.rsiValue = 100;
    } else {
      let rs = avgGain / avgLoss;
      analysis.rsiValue = 100 - (100 / (1 + rs));
    }
  }

  private calculateKDJ(highs: number[], lows: number[], closes: number[], analysis: StockAnalysis, period: number = 9): void {
    if (closes.length < period) {
      analysis.kdjK = 50;
      analysis.kdjD = 50;
      analysis.kdjJ = 50;
      return;
    }

    let recentHighs = highs.slice(-period);
    let recentLows = lows.slice(-period);
    let highestHigh = Math.max(...recentHighs);
    let lowestLow = Math.min(...recentLows);

    let rsv = (highestHigh === lowestLow) ? 50 : ((closes[closes.length - 1] - lowestLow) / (highestHigh - lowestLow)) * 100;

    analysis.kdjK = (2.0 / 3) * 50 + (1.0 / 3) * rsv;
    analysis.kdjD = (2.0 / 3) * 50 + (1.0 / 3) * analysis.kdjK;
    analysis.kdjJ = 3 * analysis.kdjK - 2 * analysis.kdjD;
  }

  private calculateBollingerBands(closes: number[], analysis: StockAnalysis, period: number = 20): void {
    if (closes.length < period) {
      analysis.bollMiddle = closes[closes.length - 1];
      analysis.bollUpper = analysis.bollMiddle;
      analysis.bollLower = analysis.bollMiddle;
      return;
    }

    let recentCloses = closes.slice(-period);
    let sum = 0;
    for (let p of recentCloses) {
      sum += p;
    }
    let sma = sum / period;

    let varianceSum = 0;
    for (let p of recentCloses) {
      varianceSum += Math.pow(p - sma, 2);
    }
    let stdDev = Math.sqrt(varianceSum / period);

    analysis.bollMiddle = sma;
    analysis.bollUpper = sma + 2 * stdDev;
    analysis.bollLower = sma - 2 * stdDev;
  }

  private calculateMLScore(analysis: StockAnalysis, historyData: StockHistoryData[]): number {
    let score = 50;
    let currentPrice = historyData[historyData.length - 1].close;

    if (currentPrice > 0 && analysis.ma5 > 0 && analysis.ma10 > 0 && analysis.ma20 > 0) {
      if (currentPrice > analysis.ma5) score += 5;
      if (currentPrice > analysis.ma10) score += 5;
      if (currentPrice > analysis.ma20) score += 5;
      if (analysis.ma5 > analysis.ma10 && analysis.ma10 > analysis.ma20) score += 10;
      if (analysis.ma5 < analysis.ma10 && analysis.ma10 < analysis.ma20) score -= 10;
    }

    if (analysis.macdValue > 0) score += 8;
    else if (analysis.macdValue < 0) score -= 8;

    if (analysis.rsiValue < 20) score += 12;
    else if (analysis.rsiValue < 30) score += 8;
    else if (analysis.rsiValue > 80) score -= 12;
    else if (analysis.rsiValue > 70) score -= 8;
    else if (analysis.rsiValue >= 40 && analysis.rsiValue <= 60) score += 3;

    if (analysis.kdjJ < 0) score += 10;
    else if (analysis.kdjJ < 20) score += 5;
    else if (analysis.kdjJ > 100) score -= 10;
    else if (analysis.kdjJ > 80) score -= 5;

    if (analysis.kdjK > analysis.kdjD && analysis.kdjK < 80) score += 5;
    else if (analysis.kdjK < analysis.kdjD && analysis.kdjK > 20) score -= 5;

    if (currentPrice > 0) {
      if (currentPrice <= analysis.bollLower) score += 8;
      else if (currentPrice <= analysis.bollMiddle) score += 3;
      else if (currentPrice >= analysis.bollUpper) score -= 8;
      else if (currentPrice >= analysis.bollMiddle) score -= 3;
    }

    if (historyData.length >= 5) {
      let recentVolume = 0;
      for (let i = historyData.length - 3; i < historyData.length; i++) {
        recentVolume += historyData[i].volume;
      }
      recentVolume /= 3;
      
      let avgVolume = 0;
      for (let i = historyData.length - 10; i < historyData.length; i++) {
        avgVolume += historyData[i].volume;
      }
      avgVolume /= 10;
      
      if (recentVolume > avgVolume * 1.5) {
        if (score > 50) score += 5;
        else score -= 5;
      }
    }

    if (historyData.length >= 3) {
      let last3 = historyData.slice(-3);
      let isUpTrend = last3[0].close < last3[1].close && last3[1].close < last3[2].close;
      let isDownTrend = last3[0].close > last3[1].close && last3[1].close > last3[2].close;

      if (isUpTrend) score += 5;
      else if (isDownTrend) score -= 5;
    }

    return score;
  }

  private normalizeScore(rawScore: number): number {
    return Math.max(0, Math.min(100, rawScore));
  }

  private getRecommendation(score: number): RecommendationType {
    if (score >= 75) return RecommendationType.StrongBuy;
    if (score >= 60) return RecommendationType.Buy;
    if (score >= 40) return RecommendationType.Hold;
    if (score >= 25) return RecommendationType.Sell;
    return RecommendationType.StrongSell;
  }

  private getRecommendationText(type: RecommendationType): string {
    switch (type) {
      case RecommendationType.StrongBuy:
        return '强烈买入';
      case RecommendationType.Buy:
        return '建议买入';
      case RecommendationType.Hold:
        return '持有观望';
      case RecommendationType.Sell:
        return '建议卖出';
      case RecommendationType.StrongSell:
        return '强烈卖出';
      default:
        return '未知';
    }
  }

  private generateReason(analysis: StockAnalysis): string {
    let reasons: string[] = [];

    if (analysis.ma5 > analysis.ma10 && analysis.ma10 > analysis.ma20) {
      reasons.push('均线呈多头排列，趋势向好');
    } else if (analysis.ma5 < analysis.ma10 && analysis.ma10 < analysis.ma20) {
      reasons.push('均线呈空头排列，趋势走弱');
    }

    if (analysis.macdValue > 0) {
      reasons.push('MACD指标显示买入信号');
    } else if (analysis.macdValue < 0) {
      reasons.push('MACD指标显示卖出信号');
    }

    if (analysis.rsiValue < 30) {
      reasons.push('RSI指标显示超卖，可能存在反弹机会');
    } else if (analysis.rsiValue > 70) {
      reasons.push('RSI指标显示超买，注意回调风险');
    }

    if (analysis.kdjJ < 0) {
      reasons.push('KDJ指标J值进入超卖区域');
    } else if (analysis.kdjJ > 100) {
      reasons.push('KDJ指标J值进入超买区域');
    }

    if (analysis.kdjK > analysis.kdjD) {
      reasons.push('KDJ形成金叉趋势');
    } else if (analysis.kdjK < analysis.kdjD) {
      reasons.push('KDJ形成死叉趋势');
    }

    if (reasons.length === 0) {
      reasons.push('各项指标显示市场处于震荡整理状态');
    }

    return reasons.join('；');
  }

  private calculateConfidence(analysis: StockAnalysis, historyData: StockHistoryData[]): number {
    let confidence = 60;

    if (historyData.length >= 60) confidence += 15;
    else if (historyData.length >= 30) confidence += 10;
    else if (historyData.length >= 20) confidence += 5;

    let rsiDeviation = Math.abs(analysis.rsiValue - 50);
    if (rsiDeviation > 30) confidence += 10;
    else if (rsiDeviation > 20) confidence += 5;

    if (analysis.macdValue !== 0) {
      let macdStrength = Math.min(Math.abs(analysis.macdValue) / analysis.bollMiddle * 1000, 10);
      confidence += macdStrength;
    }

    let agreementCount = 0;
    if (analysis.ma5 > analysis.ma10) agreementCount++;
    if (analysis.macdValue > 0) agreementCount++;
    if (analysis.rsiValue < 50) agreementCount++;
    if (analysis.kdjK > analysis.kdjD) agreementCount++;

    if (agreementCount >= 3 || agreementCount <= 1) confidence += 10;

    return Math.min(95, Math.max(40, confidence));
  }

  private getScoreColor(score: number): string {
    if (score >= 70) return '#FF4444';
    if (score >= 55) return '#FF8800';
    if (score >= 45) return '#FFAA00';
    if (score >= 30) return '#88AA88';
    return '#44AA44';
  }

  private getCurrentTime(): string {
    let now = new Date();
    return `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
  }
}
