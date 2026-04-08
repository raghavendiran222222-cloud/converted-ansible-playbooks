# win_firewall_config

Ansible role for configuring Windows Firewall rules and logging. Converted from the PowerShell script `70_Network.ps1`.

## Purpose

This role performs the following Windows Firewall configuration tasks:

- Enables firewall logging for blocked connections across all profiles
- Enables COM+ Network Access (DCOM-In) rule
- Enables ICMP Echo Request (ping) rule
- Enables File and Printer Sharing (SMB-In) rule
- Enables Windows Management Instrumentation (WMI-In) rule
- Enables Remote Desktop (TCP-In) rule

## Requirements

- Target hosts must be Windows (Server 2019, 2022, or 2025)
- The `ansible.windows` collection must be installed
- WinRM connectivity to target hosts

## Role Variables

All variables are defined in `defaults/main.yml` and can be overridden.

### `win_firewall_config_log_blocked`

Enable firewall logging for blocked connections on all profiles.

- Type: `bool`
- Default: `true`

### `win_firewall_config_rules`

List of firewall rules to enable. Each entry supports:

| Key       | Type   | Description                                      |
|-----------|--------|--------------------------------------------------|
| `name`    | string | The `DisplayName` of the Windows Firewall rule   |
| `enabled` | bool   | Whether to enable or disable the rule            |
| `profile` | string or null | Firewall profile (`Any`, `Domain`, `Private`, `Public`) or `null` to leave unchanged |

Default rules:

```yaml
win_firewall_config_rules:
  - name: "COM+ Network Access (DCOM-In)"
    enabled: true
    profile: null
  - name: "Virtual Machine Monitoring (Echo Request - ICMPv4-In)"
    enabled: true
    profile: null
  - name: "File and Printer Sharing (SMB-In)"
    enabled: true
    profile: Any
  - name: "Windows Management Instrumentation (WMI-In)"
    enabled: true
    profile: Any
  - name: "Remote Desktop - User Mode (TCP-In)"
    enabled: true
    profile: Any
```

## Example Playbook

```yaml
---
- name: Configure Windows Firewall
  hosts: all
  gather_facts: true
  roles:
    - role: win_firewall_config
```

To override variables:

```yaml
---
- name: Configure Windows Firewall with custom rules
  hosts: all
  gather_facts: true
  roles:
    - role: win_firewall_config
      vars:
        win_firewall_config_log_blocked: true
        win_firewall_config_rules:
          - name: "Remote Desktop - User Mode (TCP-In)"
            enabled: true
            profile: Domain
```

## Testing

1. Ensure WinRM connectivity to a Windows target host.
2. Run the playbook:
   ```bash
   ansible-playbook -i inventory playbook.yml
   ```
3. Verify on the target host:
   ```powershell
   # Check logging setting
   Get-NetFirewallProfile | Select-Object Name, LogBlocked

   # Check rule status
   Get-NetFirewallRule -DisplayName 'Remote Desktop - User Mode (TCP-In)' | Select-Object DisplayName, Enabled, Profile
   ```

## License

Proprietary

## Author

Xylem
