# Executive Dashboard (Odoo 19 Enterprise)

Módulo orientado a dueño/gerencia para responder en un solo panel:

> "¿Cómo voy hoy/este mes/este año y qué me preocupa?"

## Instalación

1. Copiar la carpeta `executive_dashboard` al path de addons.
2. Actualizar Apps List.
3. Instalar el módulo **Executive Dashboard**.
4. Asignar a usuarios gerenciales el grupo **CEO Dashboard**.

## Seguridad y acceso

- Crea el grupo `executive_dashboard.group_ceo`.
- Restringe menú **Gerencia > Dashboard** al grupo CEO.
- Restringe la acción principal del dashboard al grupo CEO.
- Todos los cálculos usan `company_id` activo y respetan reglas estándar multi-compañía.

## Selector global de período

Filtros disponibles:

- Hoy
- Este mes
- Este año
- Rango personalizado (`date_from` y `date_to`)

El período afecta KPIs, alertas, rankings y gráficos.

## KPIs implementados

### Ventas / Facturación

- Ventas del período
- Número de documentos
- Ticket promedio
- Comparativo de ventas contra período anterior

### Cuentas por cobrar (CXC)

- Total pendiente
- Total vencido
- Total por vencer

### Cuentas por pagar (CXP)

- Total pendiente
- Total vencido
- Total por vencer

### Caja y Bancos

- Saldo agregado contable de cuentas `asset_cash` (asientos `posted`).

### P&L contable (real)

Usa `account.move.line` en estado posted y por período:

- Ingresos: account types `income`, `income_other`
- COGS: account type `expense_direct_cost`
- Gastos: account types `expense`, `expense_depreciation`

KPIs:

- Ingresos
- COGS
- Gastos
- Utilidad Bruta = Ingresos - COGS
- Utilidad Neta = Utilidad Bruta - Gastos

## Alertas “Qué me preocupa”

- Facturas por cobrar vencidas
- Pagos a proveedores vencidos
- Productos con stock crítico (visible solo si `stock` está instalado)

## Acciones rápidas

- Ver cobranza vencida
- Ver pagos vencidos
- Registrar pago / ir a pagos
- Ver facturación del período
- Ver P&L detallado del período
- Ver productos sin ventas
- Top productos del período
- Bottom productos del período

## Productos más/menos vendidos y sin ventas

Base de cálculo:

- `account.move.line` de facturas cliente posteadas (`out_invoice`, `posted`)
- Métricas: `price_subtotal` y `quantity`

Incluye:

- Top 5 más vendidos
- Bottom 5 menos vendidos
- Productos sin ventas en período (incluye productos `sale_ok=True` con 0 ventas)

## Gráficos ejecutivos

- Ventas por día (30 días)
- Utilidad neta por día (30 días)
- Ingresos vs Gastos por mes (12 meses)
- Antigüedad CXC (0–30, 31–60, 61–90, +90)

## Performance

- Se prioriza `read_group` y agregación SQL.
- Evita lectura registro a registro para métricas agregadas.
- Cálculo on-demand (sin snapshot por defecto).

## Supuestos

- Se usan los account types estándar de Odoo para clasificación P&L.
- CXC/CXP consideran documentos `posted` con `payment_state` parcial/no pagado.
- Para saldos de caja/bancos se usa agregación contable de `asset_cash`.
