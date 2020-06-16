provider "Kubernetes"{
  config_context_cluster = "minikube"
}

resource "kubernetes_replication_controller" "my_rc_1" {
  metadata {
    name = "terraform-rc"
  }

  spec {
    replicas = 1
    selector = {
      env = "dev"
      dc = "IN"
    }
    template {
      metadata {
        labels = {
          env = "dev"
          dc = "IN"
        }
        annotations = {
          "key1" = "value1"
        }
      }

      spec {
        container {
          image = "vimal13/apache-webserver-php"
          name = "mycontainer-terraform"
        }
      }
    }
  }
}
