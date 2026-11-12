---Kiếm tra số lượng
SELECT COUNT(*) FROM gia_ngay;

---Dòng tiền toàn thị trường theo tháng và tỷ trọng ngành tiêu dùng
WITH thang AS (
    SELECT substr(Ngay, 1, 7) AS Thang,
           SUM(GT_khop) AS Toan_san,
           SUM(CASE WHEN Is_Staples = 1 THEN GT_khop END) AS Nganh
    FROM gia_ngay
    GROUP BY substr(Ngay, 1, 7)
)
SELECT Thang,
       ROUND(Toan_san, 0) AS Toan_san_ty,
       ROUND(Nganh, 0) AS Nganh_tieu_dung_ty,
       ROUND(100.0 * Nganh / Toan_san, 2) AS Ty_trong_nganh_pct,
       ROUND(100.0 * (Toan_san / LAG(Toan_san) OVER (ORDER BY Thang) - 1), 1) AS Toan_san_so_voi_thang_truoc_pct
FROM thang
ORDER BY Thang;  

---Xếp hạng lợi nhuận
SELECT RANK() OVER (ORDER BY Tong_loi_nhuan DESC) AS Hang, Ma, Ten_DN,
       ROUND(100 * Tong_loi_nhuan, 1) AS Loi_nhuan_pct,
       ROUND(100 * Max_Drawdown, 1) AS Max_Drawdown_pct
FROM tong_hop_ma
WHERE Nhom_du_lieu = 'Day_du'
ORDER BY Hang
LIMIT 10;

---Lời trên mỗi đồng sụt, so hạng với hạng lợi nhuận
SELECT Ma,
       ROUND(100 * Tong_loi_nhuan, 1) AS Loi_nhuan_pct,
       ROUND(100 * Max_Drawdown, 1) AS Max_Drawdown_pct,
       ROUND(Tong_loi_nhuan / ABS(Max_Drawdown), 2) AS Loi_tren_sut,
       RANK() OVER (ORDER BY Tong_loi_nhuan DESC) AS Hang_theo_loi_nhuan,
       RANK() OVER (ORDER BY Tong_loi_nhuan / ABS(Max_Drawdown) DESC) AS Hang_theo_loi_tren_sut
FROM tong_hop_ma
WHERE Nhom_du_lieu = 'Day_du'
ORDER BY Hang_theo_loi_tren_sut;

---Cảnh báo thanh khoản
SELECT Ma, So_phien, Zero_Volume_Days,
       ROUND(100.0 * Zero_Volume_Days / So_phien, 1) AS Ty_le_phien_trong_pct,
       ROUND(Tong_gia_tri_khop, 1) AS Tong_gia_tri_khop_ty,
       ROUND(100 * Turnover_TB, 3) AS Turnover_TB_pct_moi_ngay,
       Nhom_du_lieu
FROM tong_hop_ma
WHERE Zero_Volume_Days >= 20
ORDER BY Zero_Volume_Days DESC;

---Phân nhóm
SELECT Ma, ROUND(100 * Tong_loi_nhuan, 1) AS Loi_nhuan_pct,
       ROUND(100 * Max_Drawdown, 1) AS Max_Drawdown_pct,
       Zero_Volume_Days,
       CASE
           WHEN Nhom_du_lieu <> 'Day_du' THEN 'Xep rieng (niem yet moi)'
           WHEN Zero_Volume_Days >= 50 THEN 'B. Than trong - thanh khoan'
           WHEN Tong_loi_nhuan < 0 AND Max_Drawdown < -0.40 THEN 'C. Than trong - lo va sut sau'
           WHEN Tong_loi_nhuan > 0 AND Max_Drawdown < -0.50 THEN 'D. Loi nhung tung sut rat sau'
           WHEN Tong_loi_nhuan > 0 AND Max_Drawdown > -0.30 AND Zero_Volume_Days <= 20 THEN 'A. Uu tien theo doi'
           ELSE 'Trung tinh'
       END AS Nhom
FROM tong_hop_ma
ORDER BY Nhom, Tong_loi_nhuan DESC;

---Trung bình/ trung vị
WITH x AS (
    SELECT Tong_loi_nhuan AS v,
           ROW_NUMBER() OVER (ORDER BY Tong_loi_nhuan) AS rn,
           COUNT(*) OVER () AS n
    FROM tong_hop_ma
    WHERE Nhom_du_lieu = 'Day_du'
)
SELECT ROUND(100 * (SELECT AVG(v) FROM x), 1) AS Trung_binh_pct,
       ROUND(100 * (SELECT AVG(v) FROM x WHERE rn IN ((n + 1) / 2, (n + 2) / 2)), 1) AS Trung_vi_pct,
       (SELECT COUNT(*) FROM x WHERE v > 0) AS So_ma_loi,
       (SELECT COUNT(*) FROM x WHERE v <= 0) AS So_ma_lo;

---Truy vấn 7: Tổng giá trị khớp theo mã (biểu đồ 3.2)
SELECT Ma,
       ROUND(Tong_gia_tri_khop, 1) AS Tong_gia_tri_khop_ty
FROM tong_hop_ma
ORDER BY Tong_gia_tri_khop DESC;

---Truy vấn 8: Chuỗi theo ngày của SSC, SBT (biểu đồ 3.3)
SELECT Ma, Ngay, Cumulative_Return, GT_khop, Is_Zero_Volume
FROM gia_ngay
WHERE Ma IN ('SSC', 'SBT')
ORDER BY Ma, Ngay;