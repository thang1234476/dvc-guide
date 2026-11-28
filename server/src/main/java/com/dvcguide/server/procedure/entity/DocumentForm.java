package com.dvcguide.server.procedure.entity;

import jakarta.persistence.*;
import lombok.*;
import java.io.Serializable;

@Entity @Table(name = "thanh_phan_ho_so_bieu_mau") @IdClass(DocumentForm.Key.class)
@Getter @Setter
public class DocumentForm {
    @Id @Column(name = "thanh_phan_id") private Integer documentId;
    @Id @Column(name = "bieu_mau_id") private Integer formId;
    @Column(name = "thu_tu", nullable = false) private Integer sortOrder;
    @Data @NoArgsConstructor @AllArgsConstructor
    public static class Key implements Serializable { private Integer documentId; private Integer formId; }
}
