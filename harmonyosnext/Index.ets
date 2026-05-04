import { StockDataService } from '../services/StockDataService';
import { AIAnalysisService, StockAnalysis, RecommendationType } from '../services/AIAnalysisService';
import { StockQuote, StockHistoryData, WatchlistStock } from '../models/StockModels';

@Entry
@Component
struct Index {
  @State stockDataService: StockDataService = new StockDataService();
  @State aiAnalysisService: AIAnalysisService = new AIAnalysisService();
  
  @State searchText: string = '';
  @State selectedStock: StockQuote | null = null;
  @State currentAnalysis: StockAnalysis | null = null;
  @State watchlistStocks: WatchlistStock[] = [];
  @State isLoading: boolean = false;
  @State statusMessage: string = '就绪';
  @State showAnalysis: boolean = false;

  aboutToAppear() {
    this.loadPopularStocks();
  }

  async loadPopularStocks() {
    this.isLoading = true;
    this.statusMessage = '正在加载热门股票...';
    
    try {
      this.watchlistStocks = await this.stockDataService.getPopularStocks();
      this.statusMessage = `已加载 ${this.watchlistStocks.length} 只热门股票`;
    } catch (e) {
      this.statusMessage = '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  async searchStock() {
    if (this.searchText.trim().length === 0) {
      return;
    }

    this.isLoading = true;
    this.statusMessage = `正在搜索: ${this.searchText}`;
    
    try {
      let searchCode = this.searchText.trim();
      if (!searchCode.startsWith('sh') && !searchCode.startsWith('sz') && !searchCode.startsWith('bj')) {
        if (searchCode.startsWith('6')) {
          searchCode = 'sh' + searchCode;
        } else if (searchCode.startsWith('0') || searchCode.startsWith('3')) {
          searchCode = 'sz' + searchCode;
        } else if (searchCode.startsWith('8') || searchCode.startsWith('4')) {
          searchCode = 'bj' + searchCode;
        }
      }

      let quote = await this.stockDataService.getRealTimeQuote(searchCode);
      if (quote) {
        this.selectedStock = quote;
        this.statusMessage = `已加载 ${quote.name} 行情数据`;
        await this.analyzeStock(quote);
      } else {
        this.statusMessage = '未找到该股票';
      }
    } catch (e) {
      this.statusMessage = '搜索失败';
    } finally {
      this.isLoading = false;
    }
  }

  async analyzeStock(quote: StockQuote) {
    this.isLoading = true;
    this.statusMessage = '正在进行AI智能分析...';
    
    try {
      let historyData = await this.stockDataService.getHistoryData(quote.code, 60);
      if (historyData.length > 0) {
        this.currentAnalysis = await this.aiAnalysisService.analyzeStock(quote, historyData);
        this.showAnalysis = true;
        this.statusMessage = `AI分析完成 - ${this.currentAnalysis.recommendationText} (评分: ${this.currentAnalysis.score.toFixed(1)})`;
      } else {
        this.statusMessage = '历史数据不足，无法分析';
        this.showAnalysis = false;
      }
    } catch (e) {
      this.statusMessage = '分析失败';
      this.showAnalysis = false;
    } finally {
      this.isLoading = false;
    }
  }

  async onStockSelected(stock: WatchlistStock) {
    this.searchText = stock.code;
    await this.searchStock();
  }

  getUpColor(isUp: boolean): string {
    return isUp ? '#FF4444' : '#44AA44';
  }

  getScoreColor(score: number): string {
    if (score >= 70) return '#FF4444';
    if (score >= 55) return '#FF8800';
    if (score >= 45) return '#FFAA00';
    if (score >= 30) return '#88AA88';
    return '#44AA44';
  }

  build() {
    Stack() {
      Column() {
        // Header
        Row() {
          Column() {
            Text('📈 AI智能炒股助手')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text('实时行情 · 智能分析 · 精准决策')
              .fontSize(12)
              .fontColor('#A0A0B0')
              .margin({ top: 5 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#2D2D3D')

        Scroll() {
          Column() {
            // Search Bar
            Row() {
              TextInput({ placeholder: '输入股票代码，如：600519 或 sh600519', text: this.searchText })
                .backgroundColor('#2D2D3D')
                .fontColor('#FFFFFF')
                .placeholderColor('#A0A0B0')
                .height(45)
                .borderRadius(8)
                .margin({ right: 10 })
                .layoutWeight(1)
                .onChange((value: string) => {
                  this.searchText = value;
                })

              Button('搜索')
                .backgroundColor('#00D4AA')
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
                .height(45)
                .width(100)
                .borderRadius(8)
                .onClick(() => {
                  this.searchStock();
                })
            }
            .width('100%')
            .padding(15)
            .backgroundColor('#2D2D3D')
            .borderRadius(12)
            .margin({ top: 15, left: 15, right: 15 })

            // Stock Info Card
            if (this.selectedStock) {
              Column() {
                Row() {
                  Column() {
                    Text(this.selectedStock.name)
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FFFFFF')
                    Text(this.selectedStock.code)
                      .fontSize(12)
                      .fontColor('#A0A0B0')
                      .margin({ top: 5 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Column() {
                    Text(this.selectedStock.currentPrice.toFixed(2))
                      .fontSize(28)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.getUpColor(this.selectedStock.isUp))
                    Text(`${this.selectedStock.changePercent > 0 ? '+' : ''}${this.selectedStock.changePercent.toFixed(2)}%`)
                      .fontSize(16)
                      .fontColor(this.getUpColor(this.selectedStock.isUp))
                  }
                  .alignItems(HorizontalAlign.End)
                }
                .width('100%')

                Divider()
                  .color('#3D3D4D')
                  .margin({ top: 15, bottom: 15 })

                // Stock Details Grid
                Grid() {
                  GridItem() {
                    this.InfoItem('今开', this.selectedStock.openPrice.toFixed(2))
                  }
                  GridItem() {
                    this.InfoItem('最高', this.selectedStock.highPrice.toFixed(2), '#FF4444')
                  }
                  GridItem() {
                    this.InfoItem('最低', this.selectedStock.lowPrice.toFixed(2), '#44AA44')
                  }
                  GridItem() {
                    this.InfoItem('成交量', `${(this.selectedStock.volume / 10000).toFixed(2)}万手`)
                  }
                  GridItem() {
                    this.InfoItem('昨收', this.selectedStock.previousClose.toFixed(2))
                  }
                  GridItem() {
                    this.InfoItem('更新时间', this.selectedStock.lastUpdateTime)
                  }
                }
                .columnsTemplate('1fr 1fr 1fr')
                .rowsGap(10)
                .columnsGap(10)
                .width('100%')
              }
              .padding(15)
              .backgroundColor('#2D2D3D')
              .borderRadius(12)
              .margin({ top: 15, left: 15, right: 15 })
            }

            // AI Analysis Button
            if (this.selectedStock) {
              Button('🤖 AI智能分析')
                .backgroundColor('#00D4AA')
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
                .fontSize(16)
                .height(50)
                .width('100%')
                .margin({ top: 15, left: 15, right: 15 })
                .borderRadius(8)
                .onClick(() => {
                  if (this.selectedStock) {
                    this.analyzeStock(this.selectedStock);
                  }
                })
            }

            // Analysis Result Card
            if (this.showAnalysis && this.currentAnalysis) {
              Column() {
                Text('📊 AI分析报告')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .width('100%')
                  .margin({ bottom: 15 })

                Row() {
                  Column() {
                    Text('综合评分')
                      .fontSize(12)
                      .fontColor('#A0A0B0')
                    Text(this.currentAnalysis.score.toFixed(1))
                      .fontSize(36)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.getScoreColor(this.currentAnalysis.score))
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Column() {
                    Text('AI建议')
                      .fontSize(12)
                      .fontColor('#A0A0B0')
                    Text(this.currentAnalysis.recommendationText)
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#00D4AA')
                  }
                  .alignItems(HorizontalAlign.End)
                }
                .width('100%')

                Divider()
                  .color('#3D3D4D')
                  .margin({ top: 15, bottom: 15 })

                Text('技术指标')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .width('100%')
                  .margin({ bottom: 10 })

                Grid() {
                  GridItem() {
                    this.IndicatorItem('MACD', this.currentAnalysis.macdValue.toFixed(4))
                  }
                  GridItem() {
                    this.IndicatorItem('RSI(14)', this.currentAnalysis.rsiValue.toFixed(2))
                  }
                  GridItem() {
                    this.IndicatorItem('KDJ-K', this.currentAnalysis.kdjK.toFixed(2))
                  }
                  GridItem() {
                    this.IndicatorItem('KDJ-D', this.currentAnalysis.kdjD.toFixed(2))
                  }
                  GridItem() {
                    this.IndicatorItem('MA5', this.currentAnalysis.ma5.toFixed(2))
                  }
                  GridItem() {
                    this.IndicatorItem('MA20', this.currentAnalysis.ma20.toFixed(2))
                  }
                }
                .columnsTemplate('1fr 1fr')
                .rowsGap(10)
                .columnsGap(10)
                .width('100%')
                .margin({ top: 10 })

                Divider()
                  .color('#3D3D4D')
                  .margin({ top: 15, bottom: 15 })

                Text('分析理由')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .width('100%')
                  .margin({ bottom: 10 })

                Text(this.currentAnalysis.reason)
                  .fontSize(13)
                  .fontColor('#A0A0B0')
                  .width('100%')
                  .margin({ bottom: 10 })

                Divider()
                  .color('#3D3D4D')
                  .margin({ top: 15, bottom: 15 })

                Row() {
                  Column() {
                    Text('可信度')
                      .fontSize(12)
                      .fontColor('#A0A0B0')
                    Text(`${this.currentAnalysis.confidence.toFixed(0)}%`)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#00D4AA')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Text(`分析时间: ${this.currentAnalysis.analysisTime}`)
                    .fontSize(12)
                    .fontColor('#A0A0B0')
                }
                .width('100%')
              }
              .padding(15)
              .backgroundColor('#2D2D3D')
              .borderRadius(12)
              .margin({ top: 15, left: 15, right: 15 })
            }

            // Popular Stocks Card
            Column() {
              Text('⭐ 热门股票')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .width('100%')
                .margin({ bottom: 15 })

              List() {
                ForEach(this.watchlistStocks, (stock: WatchlistStock, index: number) => {
                  ListItem() {
                    Row() {
                      Column() {
                        Text(stock.name)
                          .fontSize(15)
                          .fontWeight(FontWeight.Bold)
                          .fontColor('#FFFFFF')
                        Text(stock.code)
                          .fontSize(11)
                          .fontColor('#A0A0B0')
                          .margin({ top: 3 })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      Column() {
                        Text(stock.currentPrice > 0 ? stock.currentPrice.toFixed(2) : '--')
                          .fontSize(15)
                          .fontWeight(FontWeight.Bold)
                          .fontColor('#FFFFFF')
                        Text(stock.changePercent !== 0 ? `${stock.changePercent > 0 ? '+' : ''}${stock.changePercent.toFixed(2)}%` : '--')
                          .fontSize(12)
                          .fontColor(this.getUpColor(stock.changePercent > 0))
                          .margin({ top: 3 })
                      }
                      .alignItems(HorizontalAlign.End)
                    }
                    .width('100%')
                    .padding(10)
                    .onClick(() => {
                      this.onStockSelected(stock);
                    })
                  }
                })
              }
              .width('100%')
            }
            .padding(15)
            .backgroundColor('#2D2D3D')
            .borderRadius(12)
            .margin({ top: 15, left: 15, right: 15, bottom: 15 })

            // Bottom spacing
            Blank()
              .height(60)
          }
          .width('100%')
        }
        .layoutWeight(1)

        // Status Bar
        Row() {
          if (this.isLoading) {
            LoadingProgress()
              .width(30)
              .height(30)
              .color('#00D4AA')
              .margin({ right: 10 })
          }

          Text(this.statusMessage)
            .fontSize(12)
            .fontColor('#A0A0B0')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding(15)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#1E1E2E')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1E1E2E')
  }

  @Builder
  InfoItem(label: string, value: string, color?: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#A0A0B0')
      Text(value)
        .fontSize(14)
        .fontColor(color ?? '#FFFFFF')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  IndicatorItem(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#A0A0B0')
      Text(value)
        .fontSize(14)
        .fontColor('#FFFFFF')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
