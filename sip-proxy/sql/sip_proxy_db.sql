-- MySQL dump 10.13  Distrib 5.5.34, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: sip_proxy_db
-- ------------------------------------------------------
-- Server version	5.5.34-0ubuntu0.13.04.1
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
-- Table structure for table `registered_users`
--
DROP TABLE IF EXISTS `registered_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `registered_users` (
  `extension` varchar(10) NOT NULL DEFAULT '',
  `IP_address` varchar(15) DEFAULT NULL,
  `port` int(11) DEFAULT NULL,
  `registered_ts` timestamp NULL DEFAULT NULL,
  `expiration_ts` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`extension`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table `registered_users`
--
LOCK TABLES `registered_users` WRITE;
/*!40000 ALTER TABLE `registered_users` DISABLE KEYS */;
/*!40000 ALTER TABLE `registered_users` ENABLE KEYS */;
UNLOCK TABLES;
--
-- Table structure for table `sip_calls`
--
DROP TABLE IF EXISTS `sip_calls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sip_calls` (
  `from_ext` varchar(10) DEFAULT NULL,
  `to_ext` varchar(10) DEFAULT NULL,
  `dialed_ts` timestamp NULL DEFAULT NULL,
  `ringing_ts` timestamp NULL DEFAULT NULL,
  `answered_ts` timestamp NULL DEFAULT NULL,
  `ended_ts` timestamp NULL DEFAULT NULL,
  `state` varchar(20) DEFAULT NULL,
  `call_id` varchar(80) NOT NULL DEFAULT '',
  PRIMARY KEY (`call_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table `sip_calls`
--
LOCK TABLES `sip_calls` WRITE;
/*!40000 ALTER TABLE `sip_calls` DISABLE KEYS */;
/*!40000 ALTER TABLE `sip_calls` ENABLE KEYS */;
UNLOCK TABLES;
--
-- Table structure for table `sip_messages`
--
DROP TABLE IF EXISTS `sip_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sip_messages` (
  `src` varchar(20) DEFAULT NULL,
  `dst` varchar(20) DEFAULT NULL,
  `first_line` varchar(60) DEFAULT NULL,
  `sent_ts` timestamp NULL DEFAULT NULL,
  `transaction_id` int(11) DEFAULT NULL,
  `call_id` varchar(80) DEFAULT NULL,
  `message` varchar(1500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table `sip_messages`
--
LOCK TABLES `sip_messages` WRITE;
/*!40000 ALTER TABLE `sip_messages` DISABLE KEYS */;
/*!40000 ALTER TABLE `sip_messages` ENABLE KEYS */;
UNLOCK TABLES;
--
-- Table structure for table `sip_transactions`
--
DROP TABLE IF EXISTS `sip_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sip_transactions` (
  `transaction_id` int(11) NOT NULL AUTO_INCREMENT,
  `src` varchar(20) DEFAULT NULL,
  `cseq_num` int(11) DEFAULT NULL,
  `call_id` varchar(80) DEFAULT NULL,
  PRIMARY KEY (`transaction_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table `sip_transactions`
--
LOCK TABLES `sip_transactions` WRITE;
/*!40000 ALTER TABLE `sip_transactions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sip_transactions` ENABLE KEYS */;
UNLOCK TABLES;
--
-- Table structure for table `user_accounts`
--
DROP TABLE IF EXISTS `user_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_accounts` (
  `extension` varchar(10) DEFAULT NULL,
  `HA1` varchar(32) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table `user_accounts`
--
LOCK TABLES `user_accounts` WRITE;
/*!40000 ALTER TABLE `user_accounts` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_accounts` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
-- Dump completed on 2013-11-22 22:02:07