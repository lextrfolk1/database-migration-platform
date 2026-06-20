package com.lextr.migrationplatform;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.lextr.migrationplatform.controller.ApiExceptionHandler;
import com.lextr.migrationplatform.controller.MigrationPlatformController;
import com.lextr.migrationplatform.dto.ExecutionResponse;
import com.lextr.migrationplatform.dto.ExecutionTargetResponse;
import com.lextr.migrationplatform.dto.MigrationActionRequest;
import com.lextr.migrationplatform.exception.ServiceNotFoundException;
import com.lextr.migrationplatform.mapper.MigrationRequestMapper;
import com.lextr.migrationplatform.orchestration.MigrationPlatformOrchestrator;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(MigrationPlatformController.class)
@Import({ApiExceptionHandler.class, MigrationRequestMapper.class})
class MigrationPlatformControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private MigrationPlatformOrchestrator orchestrator;

    @MockBean
    private com.lextr.migrationplatform.config.MigrationPlatformProperties properties;

    @Test
    void runsMigrationRequest() throws Exception {
        when(properties.getDefaultRequestedBy()).thenReturn("dba");
        when(orchestrator.run(any())).thenReturn(new ExecutionResponse(
                "exec-1",
                "SERVICE",
                "SUCCESS",
                List.of(new ExecutionTargetResponse("generic-service", "postgres-main-dev", "postgres", "dev",
                        "flyway_history_generic_service", "SUCCESS", List.of(), null, null, List.of()))
        ));

        mockMvc.perform(post("/migrations/run")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new MigrationActionRequest(
                                "service", "generic-service", "postgres-main-dev", null, "dev", "delta",
                                false, false, false, false, "dba"
                        ))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.executionId").value("exec-1"))
                .andExpect(jsonPath("$.status").value("SUCCESS"));
    }

    @Test
    void mapsServiceErrorsToBadRequest() throws Exception {
        when(properties.getDefaultRequestedBy()).thenReturn("dba");
        when(orchestrator.run(any())).thenThrow(new ServiceNotFoundException("missing"));

        mockMvc.perform(post("/migrations/run")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new MigrationActionRequest(
                                "service", "generic-service", "postgres-main-dev", null, "dev", "delta",
                                false, false, false, false, "dba"
                        ))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("BAD_REQUEST"))
                .andExpect(jsonPath("$.message").value("missing"));
    }
}
