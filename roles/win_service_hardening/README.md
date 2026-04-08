# win_service_hardening

Ansible role for Windows Server service hardening. Disables unnecessary Windows services to reduce the attack surface, converted from the PowerShell script `60_inactivate_services.ps1`.

## What it does

1. Validates the target host is a Windows system.
2. Disables and stops 33 unnecessary services using `ansible.windows.win_service`.
3. Disables 4 locked services (that cannot be managed via `Set-Service`) by setting their registry `Start` value to `4` (disabled).
4. Reports which services were successfully disabled and which were skipped.

## Requirements

- Ansible 2.14 or later
- `ansible.windows` collection installed
- WinRM connectivity to target Windows hosts

## Role Variables

All variables are defined in `defaults/main.yml` and can be overridden.

### `win_service_hardening_services`

List of Windows service names to disable via `win_service`. These are stopped and set to `disabled` start mode. Services that do not exist on a given host are silently skipped.

Default: 33 services including `AxInstSV`, `bthserv`, `CDPUserSvc`, `Audiosrv`, `WpnService`, and others.

### `win_service_hardening_registry_services`

List of locked service names that must be disabled via registry modification. The role sets `HKLM:\SYSTEM\CurrentControlSet\Services\<name>\Start` to `4` (disabled).

Default: `ScDeviceEnum`, `RmSvc`, `NgcCtnrSvc`, `NgcSvc`

## Example Playbook

```yaml
---
- name: Harden Windows services
  hosts: all
  gather_facts: true
  roles:
    - win_service_hardening
```

### Override the service list

```yaml
---
- name: Harden Windows services (custom list)
  hosts: all
  gather_facts: true
  roles:
    - role: win_service_hardening
      win_service_hardening_services:
        - bthserv
        - MapsBroker
        - SSDPSRV
      win_service_hardening_registry_services:
        - NgcSvc
```

## Testing

1. Set up a Windows Server target with WinRM enabled.
2. Run the playbook:
   ```bash
   ansible-playbook -i inventory playbooks/win_service_hardening.yml
   ```
3. Verify services are disabled on the target:
   ```powershell
   Get-Service AxInstSV, bthserv, SSDPSRV | Select-Object Name, Status, StartType
   ```
4. Verify registry-disabled services:
   ```powershell
   Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NgcSvc" -Name Start
   ```

## Supported Platforms

- Windows Server 2019
- Windows Server 2022
- Windows Server 2025

## License

Proprietary

## Author

Xylem
