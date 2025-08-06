# Ashfolio Version & Feature Matrix

## Current Version: v0.25.0 (Production-Ready Beta)

*Based on comprehensive .kiro project analysis*  
*Semantic Version: 0.25.0 represents near-production completion with 25/29 tasks complete (86%)*

---

## v0.25.0 Complete Feature Set (Production-Ready)

### 🚀 **Core Portfolio Management**

#### **User & Account Management**
- ✅ **Single Default User**: Simplified local-only user model
- ✅ **Investment Accounts**: Create, edit, delete investment accounts (Schwab, Fidelity, etc.)
- ✅ **Account Exclusion**: Toggle accounts in/out of portfolio calculations
- ✅ **Manual Balance Entry**: Enter account balances with timestamp tracking
- ✅ **Multi-Platform Support**: Support for various brokerage platforms

#### **Investment Symbols & Assets**  
- ✅ **Symbol Management**: Add stocks, ETFs, crypto, and other asset types
- ✅ **Asset Classification**: Automatic categorization by asset class
- ✅ **Current Price Tracking**: Yahoo Finance integration for price data
- ✅ **Price Timestamps**: Track when prices were last updated
- ✅ **Multi-Asset Support**: Stocks, ETFs, crypto (BTC-USD), bonds, commodities

#### **Transaction Recording**
- ✅ **Complete CRUD Operations**: Create, read, update, delete transactions
- ✅ **Transaction Types**: BUY, SELL, DIVIDEND, FEE, INTEREST, LIABILITY
- ✅ **Financial Data**: Quantity, price, fees, dates, total amounts
- ✅ **Account Association**: Link transactions to specific accounts
- ✅ **Data Validation**: Comprehensive validation for financial accuracy

### 📊 **Portfolio Analytics & Calculations**

#### **Portfolio Valuation**
- ✅ **Real-Time Portfolio Value**: Calculate total portfolio worth
- ✅ **Holdings Summary**: Current positions across all accounts  
- ✅ **Cost Basis Calculation**: FIFO (First In, First Out) methodology
- ✅ **Profit & Loss Analysis**: Individual holding and total portfolio P&L
- ✅ **Return Calculations**: Percentage returns with color-coded display

#### **Advanced Calculator Engine**
- ✅ **Dual Calculator Architecture**: Main calculator + specialized holdings calculator
- ✅ **Multi-Account Aggregation**: Calculate across multiple investment accounts
- ✅ **Excluded Account Handling**: Respect account exclusion settings
- ✅ **Financial Precision**: Decimal-based calculations for accuracy

### 🖥️ **User Interface & Experience**

#### **Dashboard & Navigation**
- ✅ **Real-Time Dashboard**: Live portfolio overview with key metrics
- ✅ **Responsive Design**: Mobile, tablet, and desktop optimized
- ✅ **Professional Styling**: Clean, modern interface with Tailwind CSS
- ✅ **Navigation System**: Intuitive menu with active state management

#### **Data Display & Interaction**
- ✅ **Holdings Table**: Sortable, detailed view of all positions
- ✅ **Color-Coded P&L**: Green/red indicators for gains/losses
- ✅ **Currency Formatting**: Professional financial number display
- ✅ **Modal Forms**: User-friendly account and transaction entry
- ✅ **Loading States**: Visual feedback during operations
- ✅ **Error Handling**: User-friendly error messages and recovery

### 🔧 **Technical Foundation**

#### **Market Data Integration**  
- ✅ **Yahoo Finance API**: Real-time price fetching with error handling
- ✅ **Manual Price Updates**: **FULLY IMPLEMENTED** User-initiated price refresh system
- ✅ **Price Caching**: ETS-based caching for performance
- ✅ **Batch Processing**: Efficient multi-symbol price updates
- ✅ **PriceManager GenServer**: Complete price coordination with loading states

#### **Data Management**
- ✅ **SQLite Database**: Local file-based storage for privacy
- ✅ **Database Migrations**: Comprehensive schema management
- ✅ **Performance Indexes**: Optimized query performance
- ✅ **Data Validation**: Business logic validation via Ash Framework
- ✅ **Backup System**: Database backup and restore utilities

#### **Development & Quality**
- ✅ **Comprehensive Testing**: 192+ automated tests (100% passing)
- ✅ **Error Handling**: Centralized ErrorHandler system with user-friendly messaging
- ✅ **Development Tools**: Just task runner for streamlined workflows  
- ✅ **Ash Framework**: Complete business logic implementation (no direct Ecto)
- ✅ **Code Quality**: Strict coding standards, clean architecture, comprehensive documentation

---

## Technology Stack (v0.25.0)

### **Core Framework**
- **Elixir**: 1.14+ (concurrent, fault-tolerant backend)
- **Phoenix**: 1.7+ (modern web framework)
- **Phoenix LiveView**: Real-time user interface without JavaScript complexity

### **Business Logic**
- **Ash Framework**: 3.0+ (comprehensive business logic layer)
- **AshSqlite**: Database adapter with proper validations

### **Data & Storage**  
- **SQLite**: Local database for single-user privacy
- **ETS**: In-memory caching for performance
- **Decimal**: Financial precision arithmetic

### **External Integrations**
- **Yahoo Finance API**: Market price data
- **HTTPoison**: HTTP client for API calls

### **Development & Quality**
- **ExUnit**: Comprehensive test suite
- **Mox**: External service mocking
- **Credo**: Code quality analysis
- **Just**: Modern task runner

---

## Supported Platforms (v0.25.0)

### **Primary Platform**
- **macOS**: 12.0+ (Monterey)
  - Apple Silicon (M1/M2): Fully optimized
  - Intel Macs: Compatible

### **System Requirements**
- **RAM**: 8GB minimum, 16GB+ recommended
- **Storage**: 10GB+ free space
- **Network**: Internet connection for price updates

---

## Known Limitations (v0.25.0)

### **By Design (Phase 1 Constraints)**
- **Single User**: No multi-user support (local personal use)
- **USD Only**: All calculations in US Dollars
- **Manual Price Updates**: No automatic refresh (user-initiated only) ✅ **FULLY IMPLEMENTED**
- **Local Only**: No cloud sync or backup

### **Technical Limitations**
- **Platform Support**: Currently macOS-optimized only
- **Price Source**: Yahoo Finance dependency
- **Database**: SQLite file size limits (adequate for personal use)

---

## Version History

### v0.25.0 (Current - Production-Ready Beta)
- **Phase 9 Complete**: Full transaction management CRUD operations
- **25/29 tasks complete**: 86% overall project completion
- **All core features**: Portfolio management, accounts, transactions, price refresh
- **192+ tests passing**: Comprehensive test coverage
- **Ready for production use** with Phase 10 polish remaining

### Historical Development
- **v0.20.0**: Dashboard and holdings table complete
- **v0.15.0**: Portfolio calculations and market data integration
- **v0.10.0**: Core data models and database foundation
- **v0.1.0**: Initial Phoenix project with Ash Framework setup

---

## Future Roadmap

### **v1.0.0 - Production Release** (Next - Phase 10)
- **Task 27**: Complete responsive design and accessibility (WCAG AA)  
- **Task 28**: 100% test coverage completion
- **Task 29**: Final integration testing and performance validation
- **Polish**: PubSub events, error message refinement, loading states

### **v1.1.0 - Enhanced Features**
- Multi-currency support
- Additional price data sources  
- Automatic price refresh options
- Enhanced reporting and analytics

### **v1.2.0 - Platform Expansion**
- Windows and Linux support
- Distribution packaging
- Installation automation

### **v2.0.0 - Advanced Features**
- Multi-user support (optional)
- Advanced portfolio analytics  
- Data import/export capabilities
- Professional reporting and charting

---

## Installation & Usage

### **Quick Start**
```bash
git clone https://github.com/mdstaff/ashfolio.git
cd ashfolio
just dev
# Open http://localhost:4000
```

### **Requirements Check**
```bash
./scripts/verify-setup.sh
```

### **Documentation**
- **Setup**: [DEVELOPMENT_SETUP.md](docs/DEVELOPMENT_SETUP.md)
- **Architecture**: [ARCHITECTURE.md](docs/ARCHITECTURE.md)  
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)

---

## Support & Community

- **Issues**: [GitHub Issues](https://github.com/mdstaff/ashfolio/issues)
- **Documentation**: Project `/docs` directory
- **Code**: Phoenix/Elixir best practices

*Last Updated: August 6, 2025*