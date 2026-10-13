import 'package:flutter/material.dart';
import '../data/banks_data.dart';

class BankDirectoryWidget extends StatefulWidget {
  final bool showHeader;
  final bool isCompact;

  const BankDirectoryWidget({
    super.key,
    this.showHeader = true,
    this.isCompact = false,
  });

  @override
  State<BankDirectoryWidget> createState() => _BankDirectoryWidgetState();
}

class _BankDirectoryWidgetState extends State<BankDirectoryWidget> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BankInfo> get _filteredBanks {
    return BankDataRepository.banks.where((b) {
      final matchesCategory = _selectedCategory == 'all' || b.category == _selectedCategory;
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          b.name.toLowerCase().contains(q) ||
          b.code.toLowerCase().contains(q) ||
          b.app.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showBankGuideModal(BuildContext context, BankInfo bank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 48,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildBankLogo(bank, width: 48, height: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Ứng dụng: ${bank.app} (${bank.code})',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 14),

            const Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: Color(0xFFD97706), size: 18),
                SizedBox(width: 6),
                Text(
                  'HƯỚNG DẪN BẬT THÔNG BÁO OTT:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                bank.guide,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF78350F), height: 1.45),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tương thích 100% với gói ứng dụng: ${bank.pkg}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBanks;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TIÊU ĐỀ SECTION GIỐNG TRANG WEB
          if (widget.showHeader) ...[
            Center(
              child: Column(
                children: const [
                  Text(
                    'Hỗ trợ 65+ ngân hàng & ví điện tử',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Logo các ngân hàng & ví phổ biến — app đọc thông báo push tức thì từ tất cả nguồn dưới đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 2. Ô TÌM KIẾM NGÂN HÀNG
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Tìm ngân hàng, ví (VD: VCB, MB, MoMo...)',
                hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF64748B)),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          const SizedBox(height: 12),

          // 3. TABS PHÂN LOẠI (TẤT CẢ, THƯƠNG MẠI, NGÂN HÀNG SỐ, VÍ ĐIỆN TỬ, DOANH NGHIỆP)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryTab(
                  'all',
                  'Tất cả (${BankDataRepository.banks.length})',
                ),
                const SizedBox(width: 6),
                _buildCategoryTab(
                  'commercial',
                  'Thương mại (${BankDataRepository.banks.where((b) => b.category == 'commercial').length})',
                ),
                const SizedBox(width: 6),
                _buildCategoryTab(
                  'neobank',
                  'Ngân hàng số (${BankDataRepository.banks.where((b) => b.category == 'neobank').length})',
                ),
                const SizedBox(width: 6),
                _buildCategoryTab(
                  'ewallet',
                  'Ví điện tử (${BankDataRepository.banks.where((b) => b.category == 'ewallet').length})',
                ),
                const SizedBox(width: 6),
                _buildCategoryTab(
                  'business',
                  'Doanh nghiệp (${BankDataRepository.banks.where((b) => b.category == 'business').length})',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. DANH SÁCH LOGO CHUẨN ĐẸP NHƯ GIAO DIỆN TRANG WEB
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Không tìm thấy ngân hàng khớp với "$_searchQuery"',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 460 ? 5 : 4;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.32,
                  ),
                  itemBuilder: (context, index) {
                    final b = filtered[index];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showBankGuideModal(context, b),
                        child: Tooltip(
                          message: '${b.name} (${b.app})',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x05000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _buildBankLogo(b, width: 46, height: 26),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

          const SizedBox(height: 14),
          Center(
            child: Text(
              '💡 Bấm vào logo bất kỳ để xem hướng dẫn bật thông báo OTT chi tiết.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String cat, String label) {
    final isSelected = _selectedCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildBankLogo(BankInfo bank, {double width = 46, double height = 26}) {
    final key = bank.assetKey;
    return Image.asset(
      'assets/images/banks/$key.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        // Fallback 1: Local web asset path
        return Image.network(
          'assets/banks/$key.png',
          width: width,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (ctx1, err1, stack1) {
            // Fallback 2: CDN network URL
            return Image.network(
              bank.logo,
              width: width,
              height: height,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (ctx2, err2, stack2) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance, size: 14, color: Color(0xFF0284C7)),
                  Text(
                    bank.code,
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
