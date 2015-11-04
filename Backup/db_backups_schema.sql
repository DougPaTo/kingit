SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE SCHEMA IF NOT EXISTS `db_backups` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;
USE `db_backups` ;

-- -----------------------------------------------------
-- Table `db_backups`.`Origem`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `db_backups`.`Origem` (
  `COD` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Nome` VARCHAR(15) NOT NULL,
  `Share` VARCHAR(25) NOT NULL,
  `IP` VARCHAR(15) NOT NULL,
  `Espaco_Total` INT NOT NULL,
  `Usuario` VARCHAR(15) NOT NULL,
  `Senha` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`COD`),
  UNIQUE INDEX `Nome_UNIQUE` (`Nome` ASC),
  UNIQUE INDEX `Origem_UNIQUE` (`Share` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `db_backups`.`Destino`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `db_backups`.`Destino` (
  `COD` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Nome` VARCHAR(15) NOT NULL,
  `Local` VARCHAR(25) NOT NULL,
  `Espaco_Total` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`COD`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `db_backups`.`LinkBackup`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `db_backups`.`LinkBackup` (
  `COD` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `COD_ORIGEM` INT UNSIGNED NOT NULL,
  `COD_DESTINO` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`COD`),
  INDEX `fk_LinkBackup_Origem1_idx` (`COD_ORIGEM` ASC),
  INDEX `fk_LinkBackup_Destino1_idx` (`COD_DESTINO` ASC),
  CONSTRAINT `fk_LinkBackup_Origem1`
    FOREIGN KEY (`COD_ORIGEM`)
    REFERENCES `db_backups`.`Origem` (`COD`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_LinkBackup_Destino1`
    FOREIGN KEY (`COD_DESTINO`)
    REFERENCES `db_backups`.`Destino` (`COD`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `db_backups`.`Logs`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `db_backups`.`Logs` (
  `COD` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `COD_LinkBackup` INT UNSIGNED NOT NULL,
  `DATA_INICIO` DATE NOT NULL,
  `DATA_FIM` DATE NOT NULL,
  `HORA_INICIO` TIME NOT NULL,
  `HORA_FIM` TIME NOT NULL,
  `Num_Files` INT NOT NULL,
  `Num_New_Files` INT NOT NULL,
  `Num_Del_Files` INT NOT NULL,
  `Num_Copy_Files` INT NOT NULL,
  `Total_Transf` FLOAT NOT NULL,
  PRIMARY KEY (`COD`),
  INDEX `fk_Logs_LinkBackup1_idx` (`COD_LinkBackup` ASC),
  CONSTRAINT `fk_Logs_LinkBackup1`
    FOREIGN KEY (`COD_LinkBackup`)
    REFERENCES `db_backups`.`LinkBackup` (`COD`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `db_backups`.`Destinatarios`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `db_backups`.`Destinatarios` (
  `COD` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Nome` VARCHAR(45) NOT NULL,
  `Email` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`COD`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `db_backups`.`Relatorios`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `db_backups`.`Relatorios` (
  `COD_LOGS` INT UNSIGNED NOT NULL,
  `COD_DESTINATARIOS` INT UNSIGNED NOT NULL,
  INDEX `fk_Relatorios_Logs1_idx` (`COD_LOGS` ASC),
  INDEX `fk_Relatorios_Destinatarios1_idx` (`COD_DESTINATARIOS` ASC),
  PRIMARY KEY (`COD_LOGS`, `COD_DESTINATARIOS`),
  CONSTRAINT `fk_Relatorios_Logs1`
    FOREIGN KEY (`COD_LOGS`)
    REFERENCES `db_backups`.`Logs` (`COD`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Relatorios_Destinatarios1`
    FOREIGN KEY (`COD_DESTINATARIOS`)
    REFERENCES `db_backups`.`Destinatarios` (`COD`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `db_backups`.`Files`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `db_backups`.`Files` (
  `COD` INT NOT NULL AUTO_INCREMENT,
  `COD_LOGS` INT UNSIGNED NOT NULL,
  `ARQUIVO` VARCHAR(45) NOT NULL,
  `Excluido` TINYINT(1) NOT NULL DEFAULT false,
  PRIMARY KEY (`COD`),
  INDEX `fk_Files_Logs1_idx` (`COD_LOGS` ASC),
  CONSTRAINT `fk_Files_Logs1`
    FOREIGN KEY (`COD_LOGS`)
    REFERENCES `db_backups`.`Logs` (`COD`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
