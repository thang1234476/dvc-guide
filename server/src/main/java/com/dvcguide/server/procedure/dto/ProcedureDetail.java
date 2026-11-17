package com.dvcguide.server.procedure.dto;

import com.dvcguide.server.common.model.*;
import com.fasterxml.jackson.databind.JsonNode;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record ProcedureDetail(ProcedureSummary procedure, String originalAgency, String audience, String conditions,
                              String portalUrl, String source, List<Case> cases, List<Document> documents,
                              List<Step> steps, List<Submission> submissions, List<Agency> agencies,
                              List<String> results, List<LegalBasis> legalBases) {

    public record Case(int id, String name, String conditions, String question) {}

    public record Document(int id, Integer caseId, String group, String name, String originalCase,
                           Short originals, Short copies, Boolean required, String notes, Form form) {}

    public record Form(int id, String code, String name, String version, LocalDate effectiveDate,
                       String docxUrl, String pdfUrl, String exampleUrl, Integer legalDocumentId,
                       List<FormInstruction> instructions) {}

    public record FormInstruction(int id, String name, String guidance, String example, String commonErrors,
                                  JsonNode coordinates) {}

    public record Step(int id, StepChannel channel, short order, String title, String description, String imageUrl) {}

    public record Submission(int id, SubmissionChannel channel, String originalChannel, BigDecimal duration,
                             String durationUnit, String originalDuration, String url, String address,
                             String openingHours, List<Fee> fees) {}

    public record Fee(int id, boolean free, BigDecimal amount, String currency, String notes) {}

    public record Agency(int id, String code, String name, AdministrativeLevel level, Integer localityId,
                         String address, Double latitude, Double longitude, String phone, String email,
                         String website, String workingHours, String ticketHours, AddressSource addressSource,
                         boolean verified, LocalDate verifiedAt, String notes) {}

    public record LegalBasis(int id, int legalDocumentId, String reference, String name, LegalDocumentType type,
                             String issuer, LocalDate issuedDate, LocalDate effectiveDate, LocalDate expiryDate,
                             LegalValidity validity, LocalDate verifiedAt, String verificationSource,
                             String url, String article) {}
}
