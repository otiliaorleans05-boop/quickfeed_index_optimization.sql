-- ========================================================
-- QUICKFEED DATABASE OPTIMIZATION SCRIPT
-- ========================================================
USE quickfeed_db;

-- 1. Đo lường kích thước Data và Index trước khi tối ưu hóa (MB)
SELECT 
    table_name AS 'Table Name',
    ROUND(data_length / (1024 * 1024), 2) AS 'Data Size (MB)',
    ROUND(index_length / (1024 * 1024), 2) AS 'Index Size (MB)',
    ROUND((data_length + index_length) / (1024 * 1024), 2) AS 'Total Size (MB)'
FROM information_schema.TABLES
WHERE table_schema = 'quickfeed_db' AND table_name = 'Posts';

-- 2. Kiểm tra danh sách Index hiện có và độ phân giải Cardinality
SHOW INDEX FROM Posts;

-- ========================================================
-- TIẾN HÀNH "PHẪU THUẬT" CẮT BỎ CÁC INDEX DƯ THỪA:
-- ========================================================

-- Xóa idx_content: Cột TEXT(255) tốn nhiều bộ nhớ B-Tree, không hiệu quả. 
-- Muốn tìm kiếm bài viết nên dùng FULLTEXT index chuyên biệt thay vì B-Tree thông thường.
ALTER TABLE Posts DROP INDEX idx_content;

-- Xóa idx_post_type: Cardinality cực thấp (chỉ có 3 giá trị: TEXT, IMAGE, VIDEO), 
-- Optimizer thường bỏ qua và quét bảng trực tiếp.
ALTER TABLE Posts DROP INDEX idx_post_type;

-- Xóa idx_is_visible: Cardinality tồi tệ nhất (chỉ có 2 giá trị: 0 và 1).
-- Chi phí bảo trì B-Tree không bù đắp được hiệu năng đọc.
ALTER TABLE Posts DROP INDEX idx_is_visible;

-- ========================================================
-- GIỮ LẠI CÁC INDEX CÓ GIÁ TRỊ CAO:
-- idx_user_id (tìm bài viết theo user)
-- idx_created_at (sắp xếp bảng tin theo thời gian đăng)
-- ========================================================

-- 3. Đo lường lại kích thước sau khi đã loại bỏ 3 Index
SELECT 
    table_name AS 'Table Name',
    ROUND(data_length / (1024 * 1024), 2) AS 'Data Size (MB)',
    ROUND(index_length / (1024 * 1024), 2) AS 'Index Size (MB)',
    ROUND((data_length + index_length) / (1024 * 1024), 2) AS 'Total Size (MB)'
FROM information_schema.TABLES
WHERE table_schema = 'quickfeed_db' AND table_name = 'Posts';