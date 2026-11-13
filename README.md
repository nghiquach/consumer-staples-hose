# Phân tích hiệu suất sinh lời, rủi ro giá và rủi ro thanh khoản – Ngành Hàng tiêu dùng thiết yếu (HOSE)

> Dự án phân tích dữ liệu mô tả (descriptive analytics) trên 2 năm giao dịch sàn HOSE (21/10/2024 – 16/10/2026), tập trung vào 35 doanh nghiệp nhóm Consumer Staples. **Đây không phải khuyến nghị đầu tư.**

---
## Báo cáo phân tích chi tiết (PDF)
Xem toàn bộ báo cáo trình bày trực quan và diễn giải chi tiết tại đây:
**[Mở Báo cáo Phân tích Ngành Hàng tiêu dùng thiết yếu (PDF)](<./report/Consumer Staples_Quách Quỳnh Thục Nghi.pdf>)**

## 1. Câu hỏi kinh doanh

1. Toàn cảnh giao dịch của thị trường trong 2 năm như thế nào, và ngành tiêu dùng thiết yếu chiếm % bao nhiêu dòng tiền?
2. Làm sao tăng hiệu suất sinh lời của danh mục cổ phiếu ngành Hàng tiêu dùng thiết yếu, đồng thời **tránh các giai đoạn sụt giảm mạnh** và **các cổ phiếu có nguy cơ mất thanh khoản**?

## 2. Phạm vi & nguồn dữ liệu

| Hạng mục | Chi tiết |
|---|---|
| Thị trường | Toàn sàn HOSE (419 mã sau khi ghép 2 file giá) |
| Ngành tiêu dùng  | Consumer Staples – 35 doanh nghiệp (danh sách từ [hsx.vn](https://www.hsx.vn/vi/quan-ly-niem-yet/co-phieu)) |
| Lịch sử giá | [CafeF – Lịch sử giao dịch HOSE](https://cafef.vn/du-lieu/lich-su-giao-dich/hose/all-1.chn) |
| Thời gian | 21/10/2024 → 16/10/2026 (492 phiên chuẩn) |

### Các file trong dự án

| File | Vai trò |
|---|---|
| `lich_su_gia_2024_2025.xlsx`, `lich_su_gia_2025_2026.xlsx` | Dữ liệu giá thô theo ngày (12 cột: Mã, Ngày, Giá đóng cửa, Giá điều chỉnh, Thay đổi, KL/GT khớp lệnh, KL/GT thỏa thuận, Giá mở/cao/thấp) |
| `ds_consumer_staples.csv` | Danh sách 35 doanh nghiệp ngành tiêu dùng (Mã CK, ISIN, FIGI, tên, KL đăng ký niêm yết, KL lưu hành, ngày niêm yết) |
| `tu_dien_du_lieu_tho.xlsx` | Từ điển dữ liệu thô |
| `ghi_chu_du_lieu.txt` | Ghi chú đặc điểm dữ liệu (định dạng số, ngày, đơn vị…) |
| `quy_tac_lam_sach.txt` | Quy tắc làm sạch dữ liệu |
| `pham_vi.txt` | Câu hỏi kinh doanh, phạm vi, định nghĩa, giới hạn |
| `queries.sql` | 8 truy vấn SQL phân tích |
| `Truy_vấn_1.csv … Truy_vấn_8.csv` | Kết quả của 8 truy vấn |

## 3. Đặc điểm dữ liệu thô

- Ngày dạng `dd/mm/yyyy`; dữ liệu xếp ngày mới nhất lên đầu.
- Bảng giá: dấu phẩy là **dấu thập phân** (`7,1`), không có dấu ngăn hàng nghìn. Giá tính theo **nghìn đồng**, giá trị khớp lệnh tính theo **tỷ đồng** (2 số lẻ).
- Bảng ngành: dấu phẩy là **dấu ngăn hàng nghìn** (`10,451,182`) và đang lưu dạng text → phải xử lý khác bảng giá.
- Hai file giá không trùng ngày (file 1 kết thúc 17/10/2025, file 2 bắt đầu 20/10/2025).

## 4. Quy trình làm sạch (tóm tắt)

1. Chuẩn hóa mã: bỏ khoảng trắng, viết hoa (`"vnm "` → `VNM`).
2. Đọc mọi cột ở dạng chữ trước, rồi mới ép kiểu số.
3. Bỏ dòng trùng theo cặp (Mã, Ngày), giữ dòng đầu.
4. Ghép 2 file giá, sắp xếp tăng dần theo Mã và Ngày.
5. **Giá thiếu hoặc = 0** → điền bằng giá phiên trước của cùng mã (giá là chuỗi liên tục); dòng đầu chuỗi bị thiếu thì bỏ.
6. **Khối lượng/giá trị thiếu** → điền 0 (thiếu nghĩa là không giao dịch, tránh tạo dòng tiền giả).
7. KL lưu hành: điền xuôi rồi điền ngược (giá trị tĩnh).
8. Left join với bảng ngành: giữ mọi mã trên sàn, mã tiêu dùng có `Is_Staples = 1`.
9. Kiểm tra chỗ nối 2 file: ngày 20/10/2025 có 0/393 mã vượt ngưỡng 7,5% → không phát hiện lệch giá.

### Phân nhóm dữ liệu theo số phiên (`Nhom_du_lieu`)

| Nhóm | Điều kiện |
|---|---|
| `Qua_ngan` | < 60 phiên |
| `Niem_yet_moi` | Niêm yết sau 21/10/2024, hoặc 60–442 phiên |
| `Day_du` | ≥ 443 phiên (90% của 492 phiên chuẩn) |

### Các cờ (flag) – gắn cờ, **không xóa** dữ liệu

| Cờ | Ý nghĩa |
|---|---|
| `Truoc_ngay_niem_yet` | Dòng có ngày sớm hơn ngày niêm yết HOSE (VD: MCH niêm yết 10/12/2025) |
| `Nghi_van_bien_do` | Biến động giá trong ngày > 7,5% (biên độ HOSE 7% + 0,5 điểm dung sai). VD: 02/02/2026 có 34 mã vượt ngưỡng |
| `Co_gian_doan` | Mã thiếu phiên trong khoảng giao dịch của chính nó |
| `Ngay_thieu_du_lieu` | Ngày có số mã giao dịch < 90% trung vị |

## 5. Các chỉ số sử dụng

| Chỉ số | Cách hiểu |
|---|---|
| **Tong_loi_nhuan** | Lợi nhuận tích lũy của mã trong cả giai đoạn (dựa trên giá điều chỉnh) |
| **Max_Drawdown** | Mức sụt giảm sâu nhất từ một đỉnh giá xuống đáy kế tiếp (số âm) – đo rủi ro giá |
| **Lời trên mỗi đồng sụt** | `Tong_loi_nhuan / ABS(Max_Drawdown)` – lợi nhuận nhận được trên mỗi 1 đơn vị sụt sâu phải chịu |
| **Intraday_Volatility** | Biên độ giật giá trong phiên – đo rủi ro giá |
| **Zero_Volume_Days** | Số phiên không có khối lượng khớp lệnh – đo rủi ro thanh khoản |
| **Turnover_Ratio / Turnover_TB** | Khối lượng khớp ÷ KL lưu hành (gần đúng vì KL lưu hành chỉ lấy tại 1 thời điểm); `Turnover_TB` là trung bình theo ngày |
| **Tỷ lệ phiên trống** | `Zero_Volume_Days / So_phien` |

## 6. Kết quả
Tổng hợp từ 8 truy vấn SQL và 10 biểu đồ trực quan hóa xoay quanh 3 luận điểm chính:

### 1. Phân bổ vĩ mô: Ngành Tiêu dùng mất dần sức hút dòng tiền khi thị trường sôi động
* **Ngành tiêu dùng không còn là an toàn để "trú ẩn":** Dòng tiền toàn sàn đạt đỉnh 966 nghìn tỷ đồng vào tháng 08/2025, nhưng tỷ trọng chảy vào nhóm Consumer Staples lại biến động thất thường và giảm từ mức trung bình **7,6%** (11/2024 – 04/2025) xuống còn **5,5%** (04/2026 – 09/2026) (Hình 1).
* **Tăng chậm hơn, giảm sâu hơn thị trường:** Khi quy về cùng gốc 100 tại tháng 11/2024, dòng tiền toàn sàn tăng gấp **3,8 lần** ở đỉnh và giữ mức **104** vào cuối kỳ (09/2026); trong khi ngành tiêu dùng chỉ đạt đỉnh **2,9 lần** và lùi sâu về mốc **69** (Hình 2). Định kiến "ngành phòng thủ tự hút tiền khi thị trường biến động" không đúng trong giai đoạn này.

### 2. Lựa chọn cổ phiếu: Kết quả phụ thuộc chủ yếu vào chọn mã, không phải chọn ngành
* **Lợi nhuận trung bình không nói lên sự tăng trưởng toàn ngành :** Lợi nhuận cộng dồn trung bình của 30 mã đủ dữ liệu đạt **+11,7%**, nhưng lợi nhuận trung vị lại âm **−0,2%** (chia đôi chính xác: 15 mã lời, 15 mã lỗ) (Hình 3, 4). Con số trung bình bị kéo lệch bởi hai mã tăng nhiều là **NAF (+142,2%)** và **SBT (+113,9%)**; nếu loại bỏ hai mã này, trung bình ngành chỉ còn **+3,4%** và trung vị giảm về **−4,0%** (Hình 5).
* **Đánh giá hiệu suất trên mỗi đơn vị rủi ro (Risk-Adjusted Return):** Khi xếp hạng theo tỷ số `Lợi nhuận / |Max Drawdown|`, thứ hạng thay đổi đáng kể: **HSL** (+76,2% nhưng từng sụt −70,4%) tụt từ hạng 3 xuống hạng 9, trong khi **SMB** (+28,4%, sụt chỉ −11,0%) vươn từ hạng 9 lên hạng 5 (Hình 6, 7). **NAF** (tỷ số 7,94) và **SBT** (tỷ số 4,86) giữ vững vị trí dẫn đầu ở cả hai tiêu chí.
* **Quy mô dòng tiền không đồng nghĩa với sinh lời:** Các mã đầu ngành có giá trị khớp lệnh lớn nhất như **MSN** (226.110 tỷ, lỗ −11,0%), **VNM** (131.579 tỷ, lỗ −3,1%) và **DBC** (lỗ −29,6%) đều ghi nhận hiệu suất âm (Hình 8).

### 3. Quản trị rủi ro thực thi: Lợi nhuận trên giấy là ảo giác nếu nhà đầu tư sập bẫy thanh khoản
* **Bẫy lợi nhuận ảo:** Một số mã có mức tăng giá tốt nhưng thanh khoản rất mỏng như **VCF** (+54,4%, 55 phiên không giao dịch, tổng giá trị khớp 2 năm chỉ 125 tỷ) và **CLC** (+36,9%, 76 phiên không giao dịch, tổng giá trị khớp 93 tỷ) — khiến nhà đầu tư khó hiện thực hóa lợi nhuận thực tế (Hình 8, 9).
* **Mất thanh khoản cục bộ:** Có 8/30 mã xuất hiện từ 20 phiên trắng thanh khoản trở lên. Điển hình là **SSC** với **252/492 phiên không có khớp lệnh** (chiếm 51,2% thời gian), tổng giá trị giao dịch 2 năm chỉ 5,2 tỷ đồng và lỗ **−27,1%**, tạo cảm giác giá đi ngang ổn định giả tạo khi đặt cạnh mã giao dịch liên tục như **SBT** (0/492 phiên trống) (Hình 9, 10).

### Phân nhóm 35 mã (theo ngưỡng quy ước của dự án)

| Nhóm | Số mã | Danh sách mã |
|---|---|---|
| **A. Ưu tiên theo dõi** (lời, MDD > −30%, ≤ 20 phiên trống) | 8 | NAF, SBT, BAF, ABT, HAG, SMB, AAM, KDC |
| **B. Thận trọng – thanh khoản** (≥ 50 phiên trống) | 5 | VCF, CLC, DAT, NSC, SSC |
| **C. Thận trọng – lỗ và sụt sâu** (lỗ, MDD < −40%) | 4 | VHC, DBC, IDI, CMX |
| **D. Lời nhưng từng sụt rất sâu** (lời, MDD < −50%) | 2 | HSL, ANV |
| **Trung tính** | 11 | LAF, PAN, VNM, ACL, SAB, MSN, LIX, MCM, FMC, LSS, BHN |
| **Xếp riêng** (niêm yết mới < 443 phiên) | 5 | MCH, AAN, AFX, HPA, ANT |

> *Các ngưỡng phân nhóm (Max Drawdown −30%, −40%, −50%; 20 và 50 phiên không giao dịch) là quy ước của báo cáo để sàng lọc danh mục, không phải chuẩn tài chính.*

### Hướng xem xét & Kết luận

| Nhóm vấn đề | Hướng xem xét | Biểu đồ |
|---|---|---|
| Ngành mất sức hút dòng tiền | Không kỳ vọng ngành tự tăng giá nhờ tính phòng thủ; đánh giá từng mã thay vì mua rải đều cả ngành | Hình 1, 2 |
| Lợi nhuận trung bình che giấu phân hóa | Báo cáo hiệu suất ngành bằng cả trung bình và trung vị | Hình 3, 4, 5 |
| Lợi nhuận cao nhưng từng sụt rất sâu | Xét thêm Max Drawdown và tỷ số Lợi nhuận / Rủi ro trước khi đưa vào danh sách theo dõi | Hình 6, 7 |
| Giao dịch thưa làm lợi nhuận khó thực hiện | Loại các mã có nhiều phiên không giao dịch hoặc tổng giá trị khớp quá thấp khỏi danh sách theo dõi | Hình 8, 9, 10 |

*Kết luận mang tính mô tả trên dữ liệu giá và khối lượng 2 năm (21/10/2024 – 16/10/2026), chưa bao gồm phân tích báo cáo tài chính doanh nghiệp và không phải khuyến nghị đầu tư.*
