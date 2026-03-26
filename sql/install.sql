-- ╔══════════════════════════════════════════╗
-- ║         SQL / INSTALL.SQL               ║
-- ║  Tabellen für qbx_firedepartmentjob     ║
-- ╚══════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS `fd_callouts` (
    `id`           INT          NOT NULL AUTO_INCREMENT,
    `callout_id`   INT          NOT NULL,
    `type`         VARCHAR(64)  NOT NULL,
    `label`        VARCHAR(128) NOT NULL,
    `coords_x`     FLOAT        NOT NULL,
    `coords_y`     FLOAT        NOT NULL,
    `coords_z`     FLOAT        NOT NULL,
    `priority`     TINYINT      NOT NULL DEFAULT 1,
    `reward`       INT          NOT NULL DEFAULT 0,
    `completed`    TINYINT(1)   NOT NULL DEFAULT 0,
    `created_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `completed_at` DATETIME              DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `fd_duty_log` (
    `id`         INT         NOT NULL AUTO_INCREMENT,
    `citizenid`  VARCHAR(64) NOT NULL,
    `duty_on`    DATETIME    NOT NULL,
    `duty_off`   DATETIME             DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `fd_stats` (
    `id`               INT         NOT NULL AUTO_INCREMENT,
    `citizenid`        VARCHAR(64) NOT NULL UNIQUE,
    `callouts_done`    INT         NOT NULL DEFAULT 0,
    `players_revived`  INT         NOT NULL DEFAULT 0,
    `total_earnings`   INT         NOT NULL DEFAULT 0,
    `last_updated`     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `fd_config` (
    `key`        VARCHAR(128) NOT NULL,
    `value`      TEXT         NOT NULL,
    `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;