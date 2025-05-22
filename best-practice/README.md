# STUDI-ECF - Projet DevOps

Ce projet est réalisé dans le cadre de la formation **Administrateur Système DevOps**.

Enoncé :

InfoLine est une nouvelle agence qui souhaite gagner le marché dans le domaine de l’actualité des
technologies sportives. L’objectif est de développer un site qui permet de montrer les actualités des
outils sportifs connectés à la technologie. Le site doit permettre la promotion et la vente de certains
produits. InfoLine souhaite distinguer entre deux types de clients : visiteurs, utilisateurs. Le visiteur
n’est pas obligé de s’inscrire ou se connecter pour voir les annonces. Par contre, pour acheter un
produit, il faut s’inscrire sur le site. Les produits sont gérés côté backoffice par des administrateurs qui
peuvent ajouter/supprimer un produit.
Après une réunion des actionnaires InfoLine, la direction a décidé de démarrer par un budget limité
dans un premier temps avec la possibilité d’augmenter la capacité si besoin.
Cela implique forcément d’aller au cloud vers des solutions qui offrent la scalabilité des ressources.
L’équipe technique a décidé de séparer les applications pour diminuer le risque d’être hors service de
l’application :
- api en java à dockerizer et déployer sur kubernetes ;
- java function pour le login des utilisateurs/admin en serverless (ex. : aws lambda) ;
- Deux applications front end en Angular (principale et backoffice) ;
- Database en postgresql.
Deux équipes sont montées, une pour le développement et l’autre pour la DevOps. Vous faites partie
de l’équipe DevOps et on vous donne toute la responsabilité pour établir l’infrastructure. Vous avez
décidé de passer par IaaS (Infrastructure As A Service) pour l’automatisation de la mise en place. Vous
faites en sorte, avec l’équipe de développement, de mettre CI/CD pour les applications. Vu la sensibilité
de l’application, la direction vous demande de monitorer l’état des applications et d’envoyer des
notifications en cas de dysfonctionnement.


## 🏗 Objectif
Mettre en place l'infrastructure d'une application web complète :
- Frontend : Angular (client et admin)
- Backend : API Java Spring Boot
- Base de données : PostgreSQL
- Déploiement : Docker, Kubernetes
- CI/CD : GitHub Actions
- Infrastructure : Terraform (IaaS)
- Monitoring : ELK (Elasticsearch + Kibana)

## 🗂 Arborescence mise en place sur Github :

STUDI-ECF/
│
├── terraform/ # Infrastructure cloud (Kubernetes, VPC, etc.)
├── k8s/ # Déploiement Kubernetes YAML
├── docker/ # Dockerfiles pour build des services
├── angular/ # Applications Angular (client & admin)
├── java-api/ # API backend Java Spring Boot
├── cicd/ # Pipelines CI/CD (GitHub Actions)
├── monitoring/ # Config ELK (Elasticsearch / Kibana)
└── README.md

