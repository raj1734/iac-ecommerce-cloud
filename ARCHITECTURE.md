# Terraform Architecture

```text
                         Route 53
                            |
                            v
                           WAF
                            |
                            v
                           ALB
                     /             \
                  AZ-A             AZ-B
                    |                |
                    +-------+--------+
                            |
                       ECS Fargate
                            |
        +-------------------+-------------------+
        |                   |                   |
     Gateway            Business Services    Config
        |                   |
        |        +----------+----------+
        |        |          |          |
       Auth     User      Catalog   Inventory
                              |          |
                              +----+-----+
                                   |
                              Cart + Order
                                   |
                    +--------------+--------------+
                    |              |              |
                  RDS          DocumentDB       Redis
                 (4 DBs)       (Catalog)      (Cache)
                                   |
                                  MSK
                                   |
                         Future Event Consumers

Payment Stub and Notification Stub:
- ECS services
- no database
- external payment provider is Future
```

## Database ownership

```text
Auth Service       -> Auth PostgreSQL
User Service       -> User PostgreSQL
Inventory Service  -> Inventory PostgreSQL
Order Service      -> Order PostgreSQL
Catalog Service    -> DocumentDB
Payment Stub       -> No DB
Notification Stub  -> No DB
```

## Communication

Synchronous:
- Gateway -> services
- Order -> Catalog
- Order -> Inventory
- Order -> Payment Stub

Asynchronous:
- Order -> MSK: OrderCreated
- Future consumers -> MSK

## Modes

### Local
No AWS resources. Run services locally with the project's local development stack.

### Dev
2 AZ networking but cost-optimized managed services. Intended for development/integration.

### Prod
2 AZ, two ECS tasks per service, Multi-AZ RDS, two DocumentDB instances, Redis replica/failover, three MSK brokers.

## Note

Two AZ is the requested project topology. Some AWS managed services may have their own minimum subnet/AZ requirements. The production-like mode should therefore be described as "production-oriented 2-AZ", not a universal recommendation for every workload.
