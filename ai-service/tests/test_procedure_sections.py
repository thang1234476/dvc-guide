from app.services.procedure_sections import supplemental_sections
from app.services.retrieval import chunks_field_title
from .test_sync import payload


def test_indexes_full_business_fields_without_rewriting_base_chunks(retriever):
    update = payload()
    procedure = update['procedure']
    procedure.update(so_quyet_dinh='QĐ-123', loai_thu_tuc='OTHER', tu_khoa=['hồ sơ đặc biệt'],
                     co_quan={'tham_quyen': 'Cơ quan có thẩm quyền thử nghiệm', 'dia_chi_tiep_nhan': '12 Đường Kiểm Thử',
                              'uy_quyen': 'Cơ quan được ủy quyền', 'phoi_hop': 'Cơ quan phối hợp'})
    procedure['ho_so'][0].update(so_ban_chinh=1, so_ban_sao=0,
                               mau_don=[{'ten': 'Tờ khai', 'url': 'https://drive.google.com/form-demo'}])
    procedure['cach_thuc'][0].update(mo_ta='Nộp vào buổi sáng')
    procedure['cach_thuc'][0]['thoi_han']['goc'] = '3 OTHER'
    procedure['ket_qua'] = [{'ten': 'Giấy xác nhận', 'ma': 'KQ-123'}]
    base = chunks_field_title(procedure)
    retriever.apply_sync(1, update)
    text = '\n'.join(retriever.state.texts)
    assert all(chunk in retriever.state.texts for chunk in base)
    for value in ['QĐ-123', 'OTHER', 'hồ sơ đặc biệt', '12 Đường Kiểm Thử', '1 bản chính', '0 bản sao',
                  'https://drive.google.com/form-demo', 'Nộp vào buổi sáng', '3 OTHER', 'KQ-123']:
        assert value in text
    changed = payload(2)
    retriever.apply_sync(1, changed)
    assert 'QĐ-123' not in '\n'.join(retriever.state.texts)


def test_optional_fields_remain_optional():
    assert supplemental_sections({'ten': 'Thủ tục'}) == []
