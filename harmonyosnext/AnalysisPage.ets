import { StockAnalysis } from '../services/AIAnalysisService';
import router from '@ohos.router';

@Entry
@Component
struct AnalysisPage {
  @State analysis: StockAnalysis | null = null;

  build() {
    Stack() {
      Column() {
        // Header
        Row() {
          Button('← 返回')
            .backgroundColor('transparent')
            .fontColor('#00D4AA')
            .fontSize(16)
            .onClick(() => {
              router.back();
            })

          Text('AI分析报告')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Blank().width(80)
        }
        .width('100%')
        .padding(15)
        .backgroundColor('#2D2D3D')

        Scroll() {
          Column() {
            if (this.analysis) {
              // Score and Recommendation
              Row() {
                Column() {
                  Text('综合评分')
                    .fontSize(14)
                    .fontColor('#A0A0B0')
                  Text(this.analysis.score.toFixed(1))
                    .fontSize(48)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.getScoreColor(this.analysis.score))
                }
                .layoutWeight(1)

                Column() {
                  Text('AI建议')
                    .fontSize(14)
                    .fontColor('#A0A0B0')
                  Text(this.analysis.recommendationText)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#00D4AA')
                  Text(this.analysis.stockName)
                    .fontSize(14)
                    .fontColor('#A0A0B0')
                    .margin({ top: 5 })
                  Text(this.analysis.stockCode)
                    .fontSize(12)
                    .fontColor('#666666')
                }
                .alignItems(HorizontalAlign.End)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(20)
              .backgroundColor('#2D2D3D')
              .borderRadius(12)
              .margin({ top: 15, left: 15, right: 15 })

              // Technical Indicators
              Column() {
                Text('技术指标详情')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .width('100%')
                  .margin({ bottom: 15 })

                Grid() {
                  GridItem() {
                    this.IndicatorCard('MACD', this.analysis.macdValue.toFixed(4), '趋势指标')
                  }
                  GridItem() {
                    this.IndicatorCard('RSI', this.analysis.rsiValue.toFixed(2), '超买超卖')
                  }
                  GridItem() {
                    this.IndicatorCard('KDJ-K', this.analysis.kdjK.toFixed(2), '随机指标')
                  }
                  GridItem() {
                    this.IndicatorCard('KDJ-D', this.analysis.kdjD.toFixed(2), '随机指标')
                  }
                  GridItem() {
                    this.IndicatorCard('KDJ-J', this.analysis.kdjJ.toFixed(2), '随机指标')
                  }
                  GridItem() {
                    this.IndicatorCard('MA5', this.analysis.ma5.toFixed(2), '5日均线')
                  }
                  GridItem() {
                    this.IndicatorCard('MA10', this.analysis.ma10.toFixed(2), '10日均线')
                  }
                  GridItem() {
                    this.IndicatorCard('MA20', this.analysis.ma20.toFixed(2), '20日均线')
                  }
                  GridItem() {
                    this.IndicatorCard('布林上轨', this.analysis.bollUpper.toFixed(2), '布林带')
                  }
                  GridItem() {
                    this.IndicatorCard('布林中轨', this.analysis.bollMiddle.toFixed(2), '布林带')
                  }
                  GridItem() {
                    this.IndicatorCard('布林下轨', this.analysis.bollLower.toFixed(2), '布林带')
                  }
                }
                .columnsTemplate('1fr 1fr')
                .rowsGap(10)
                .columnsGap(10)
                .width('100%')
              }
              .padding(15)
              .backgroundColor('#2D2D3D')
              .borderRadius(12)
              .margin({ top: 15, left: 15, right: 15 })

              // Analysis Reason
              Column() {
                Text('分析理由')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .width('100%')
                  .margin({ bottom: 10 })

                Text(this.analysis.reason)
                  .fontSize(14)
                  .fontColor('#A0A0B0')
                  .width('100%')
                  .lineHeight(24)
              }
              .padding(15)
              .backgroundColor('#2D2D3D')
              .borderRadius(12)
              .margin({ top: 15, left: 15, right: 15 })

              // Confidence
              Row() {
                Column() {
                  Text('可信度')
                    .fontSize(14)
                    .fontColor('#A0A0B0')
                  Text(`${this.analysis.confidence.toFixed(0)}%`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#00D4AA')
                }
                .layoutWeight(1)

                Text(`分析时间: ${this.analysis.analysisTime}`)
                  .fontSize(12)
                  .fontColor('#A0A0B0')
              }
              .width('100%')
              .padding(15)
              .backgroundColor('#2D2D3D')
              .borderRadius(12)
              .margin({ top: 15, left: 15, right: 15, bottom: 20 })
            } else {
              Text('暂无分析数据')
                .fontSize(18)
                .fontColor('#A0A0B0')
                .margin({ top: 100 })
            }

            Blank()
              .height(60)
          }
          .width('100%')
        }
        .layoutWeight(1)
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
  IndicatorCard(name: string, value: string, label: string) {
    Column() {
      Text(name)
        .fontSize(12)
        .fontColor('#A0A0B0')
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ top: 5 })
      Text(label)
        .fontSize(10)
        .fontColor('#666666')
        .margin({ top: 3 })
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#1E1E2E')
    .borderRadius(8)
  }

  getScoreColor(score: number): string {
    if (score >= 70) return '#FF4444';
    if (score >= 55) return '#FF8800';
    if (score >= 45) return '#FFAA00';
    if (score >= 30) return '#88AA88';
    return '#44AA44';
  }
}
