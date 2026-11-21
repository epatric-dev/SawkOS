BOOT_DIR := boot
ESP_DIR := esp
OVMF_CODE ?= /usr/share/OVMF/OVMF_CODE_4M.fd
QEMU ?= qemu-system-x86_64
CC := clang
CXX := clang++
CLANG_FORMAT ?= clang-format

SOURCE_FILES := $(shell find . -path './boot/gnu-efi' -prune -o \
	\( -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o \
	-name '*.cxx' -o -name '*.h' -o -name '*.hh' -o -name '*.hpp' -o \
	-name '*.hxx' \) \) -print)

.PHONY: all boot esp run clean fmt

all: esp

boot:
	@echo "==> Building UEFI Booter"
	@$(MAKE) --no-print-directory -C $(BOOT_DIR) all CC=$(CC) CXX=$(CXX)

fmt:
	@echo "==> Formatting source files"
	@$(CLANG_FORMAT) -i $(SOURCE_FILES)

esp: boot
	@echo "==> Preparing ESP at $(ESP_DIR)/"
	@$(MAKE) --no-print-directory -C $(BOOT_DIR) install ESP_DIR=../$(ESP_DIR)

run: esp
	@test -r "$(OVMF_CODE)" || { echo "OVMF firmware not found: $(OVMF_CODE) (set OVMF_CODE=...)"; exit 1; }
	@echo "==> Starting QEMU with OVMF ($(OVMF_CODE))"
	@$(QEMU) -machine q35 -m 256M -drive if=pflash,format=raw,unit=0,file=$(OVMF_CODE),readonly=on -drive format=raw,file=fat:rw:$(ESP_DIR)

clean:
	@echo "==> Cleaning build artifacts and ESP"
	@$(MAKE) --no-print-directory -C $(BOOT_DIR) clean
	@rm -rf $(ESP_DIR)
