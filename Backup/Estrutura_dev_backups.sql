-- MySQL dump 10.13  Distrib 5.5.44, for debian-linux-gnu (x86_64)
--
-- Host: 10.0.99.76    Database: dev_backups
-- ------------------------------------------------------
-- Server version	5.5.44-0+deb8u1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Destinatarios`
--

DROP TABLE IF EXISTS `Destinatarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Destinatarios` (
  `COD` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `NOME` varchar(45) NOT NULL,
  `EMAIL` varchar(45) NOT NULL,
  PRIMARY KEY (`COD`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Destino`
--

DROP TABLE IF EXISTS `Destino`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Destino` (
  `COD` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `Nome` varchar(15) NOT NULL,
  `Local` varchar(25) NOT NULL,
  `IP` varchar(15) NOT NULL,
  `Espaco_Total` int(11) NOT NULL,
  PRIMARY KEY (`COD`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Logs`
--

DROP TABLE IF EXISTS `Logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Logs` (
  `COD` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `DATA_INICIO` date NOT NULL,
  `DATA_FIM` date NOT NULL,
  `COD_Origem` int(10) unsigned NOT NULL,
  `COD_DESTINO` int(10) unsigned NOT NULL,
  `HORA_INICIO` time NOT NULL,
  `HORA_FIM` time NOT NULL,
  `DADOS` longtext,
  `VOLUME_UTILIZADO` int(11) DEFAULT NULL,
  PRIMARY KEY (`COD`),
  KEY `fk_COD_Origem_idx` (`COD_Origem`),
  KEY `fk_COD_DESTINO_idx` (`COD_DESTINO`),
  CONSTRAINT `fk_COD_Origem` FOREIGN KEY (`COD_Origem`) REFERENCES `Origem` (`COD`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_COD_DESTINO` FOREIGN KEY (`COD_DESTINO`) REFERENCES `Destino` (`COD`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Origem`
--

DROP TABLE IF EXISTS `Origem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Origem` (
  `COD` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `Nome` varchar(15) NOT NULL,
  `Local_Origem` varchar(25) NOT NULL,
  `IP` varchar(15) NOT NULL,
  `Espaco_Total` int(11) NOT NULL,
  `SO` char(1) NOT NULL DEFAULT 'L',
  PRIMARY KEY (`COD`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Relatorios`
--

DROP TABLE IF EXISTS `Relatorios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Relatorios` (
  `COD_LOGS` int(10) unsigned NOT NULL,
  `COD_DESTINATARIOS` int(10) unsigned NOT NULL,
  PRIMARY KEY (`COD_LOGS`,`COD_DESTINATARIOS`),
  KEY `fk_COD_DESTINATARIOS_idx` (`COD_DESTINATARIOS`),
  CONSTRAINT `fk_COD_LOGS` FOREIGN KEY (`COD_LOGS`) REFERENCES `Logs` (`COD`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_COD_DESTINATARIOS` FOREIGN KEY (`COD_DESTINATARIOS`) REFERENCES `Destinatarios` (`COD`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping events for database 'dev_backups'
--

--
-- Dumping routines for database 'dev_backups'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-08-04 13:12:00
