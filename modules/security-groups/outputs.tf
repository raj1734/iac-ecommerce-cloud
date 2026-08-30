output "alb_sg_id" { value = aws_security_group.alb.id }
output "ecs_sg_id" { value = aws_security_group.ecs.id }
output "database_sg_id" { value = aws_security_group.database.id }
output "redis_sg_id" { value = aws_security_group.redis.id }
output "msk_sg_id" { value = aws_security_group.msk.id }
