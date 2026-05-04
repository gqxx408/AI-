using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using AIStockTrader.WPF.Models;
using AIStockTrader.WPF.Services;

namespace AIStockTrader.WPF.ViewModels
{
    public class MainViewModel : INotifyPropertyChanged
    {
        private readonly IStockDataService _stockDataService;
        private readonly IAIAnalysisService _aiAnalysisService;

        private StockQuote? _selectedStockQuote;
        private StockAnalysis? _currentAnalysis;
        private string _searchText = string.Empty;
        private bool _isLoading;
        private string _statusMessage = "就绪";

        public MainViewModel()
        {
            _stockDataService = new EastMoneyStockDataService();
            _aiAnalysisService = new AIAnalysisService();

            WatchlistStocks = new ObservableCollection<WatchlistStock>();
            SearchCommand = new RelayCommand(async () => await SearchStockAsync());
            RefreshCommand = new RelayCommand(async () => await RefreshDataAsync());
            AnalyzeCommand = new RelayCommand(async () => await AnalyzeStockAsync());
        }

        public ObservableCollection<WatchlistStock> WatchlistStocks { get; }

        public StockQuote? SelectedStockQuote
        {
            get => _selectedStockQuote;
            set { _selectedStockQuote = value; OnPropertyChanged(); }
        }

        public StockAnalysis? CurrentAnalysis
        {
            get => _currentAnalysis;
            set { _currentAnalysis = value; OnPropertyChanged(); }
        }

        public string SearchText
        {
            get => _searchText;
            set { _searchText = value; OnPropertyChanged(); }
        }

        public bool IsLoading
        {
            get => _isLoading;
            set { _isLoading = value; OnPropertyChanged(); }
        }

        public string StatusMessage
        {
            get => _statusMessage;
            set { _statusMessage = value; OnPropertyChanged(); }
        }

        public ICommand SearchCommand { get; }
        public ICommand RefreshCommand { get; }
        public ICommand AnalyzeCommand { get; }

        public async Task InitializeAsync()
        {
            await LoadPopularStocksAsync();
        }

        private async Task LoadPopularStocksAsync()
        {
            try
            {
                IsLoading = true;
                StatusMessage = "正在加载热门股票...";

                var stocks = await _stockDataService.GetPopularStocksAsync();
                WatchlistStocks.Clear();
                foreach (var stock in stocks)
                {
                    WatchlistStocks.Add(stock);
                }

                StatusMessage = $"已加载 {stocks.Count} 只热门股票";
            }
            catch (Exception ex)
            {
                StatusMessage = $"加载失败: {ex.Message}";
            }
            finally
            {
                IsLoading = false;
            }
        }

        private async Task SearchStockAsync()
        {
            if (string.IsNullOrWhiteSpace(SearchText))
                return;

            try
            {
                IsLoading = true;
                StatusMessage = $"正在搜索: {SearchText}";

                string searchCode = SearchText.Trim();
                if (!searchCode.StartsWith("sh") && !searchCode.StartsWith("sz"))
                {
                    if (searchCode.StartsWith("6"))
                        searchCode = "sh" + searchCode;
                    else if (searchCode.StartsWith("0") || searchCode.StartsWith("3"))
                        searchCode = "sz" + searchCode;
                }

                var quote = await _stockDataService.GetRealTimeQuoteAsync(searchCode);
                if (quote != null)
                {
                    SelectedStockQuote = quote;
                    StatusMessage = $"已加载 {quote.Name} 行情数据";
                    await AnalyzeStockAsync();
                }
                else
                {
                    StatusMessage = "未找到该股票";
                }
            }
            catch (Exception ex)
            {
                StatusMessage = $"搜索失败: {ex.Message}";
            }
            finally
            {
                IsLoading = false;
            }
        }

        private async Task RefreshDataAsync()
        {
            if (SelectedStockQuote != null)
            {
                var updatedQuote = await _stockDataService.GetRealTimeQuoteAsync(SelectedStockQuote.Code);
                if (updatedQuote != null)
                {
                    SelectedStockQuote = updatedQuote;
                    StatusMessage = "行情数据已更新";
                }
            }
        }

        private async Task AnalyzeStockAsync()
        {
            if (SelectedStockQuote == null)
                return;

            try
            {
                IsLoading = true;
                StatusMessage = "正在进行AI智能分析...";

                var historyData = await _stockDataService.GetHistoryDataAsync(SelectedStockQuote.Code, 60);
                if (historyData.Count > 0)
                {
                    var analysis = await _aiAnalysisService.AnalyzeStockAsync(SelectedStockQuote, historyData);
                    CurrentAnalysis = analysis;
                    StatusMessage = $"AI分析完成 - {analysis.RecommendationText} (评分: {analysis.Score:F1})";
                }
                else
                {
                    StatusMessage = "历史数据不足，无法分析";
                }
            }
            catch (Exception ex)
            {
                StatusMessage = $"分析失败: {ex.Message}";
            }
            finally
            {
                IsLoading = false;
            }
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    public class RelayCommand : ICommand
    {
        private readonly Action _execute;
        private readonly Func<bool>? _canExecute;

        public RelayCommand(Action execute, Func<bool>? canExecute = null)
        {
            _execute = execute;
            _canExecute = canExecute;
        }

        public event EventHandler? CanExecuteChanged
        {
            add { CommandManager.RequerySuggested += value; }
            remove { CommandManager.RequerySuggested -= value; }
        }

        public bool CanExecute(object? parameter)
        {
            return _canExecute == null || _canExecute();
        }

        public void Execute(object? parameter)
        {
            _execute();
        }
    }
}
