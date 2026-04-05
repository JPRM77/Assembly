extern printf

section .data
	tolerancia dq 0.01
	iterations dd 0
	setpoint dq 100.0
	atual dq 0.0
	erro dq 100.0
	erro_acumulado dq 0.0
	erro_anterior dq 0.0
	kp dq 0.5
	ki dq 0.1
	kd dq 0.2
	d_t dq 1.0
	msg db "Iteração: %d; Erro: %.2f; Saída: %.2f; P: %.2f; I: %.2f; D: %.2f; Nova Pos: %.2f", 10, 0
	success db "Você alcançou o setpoint!", 10, 0

section .bss
	saida resq 1
	saida_P resq 1
	saida_I resq 1
	saida_D resq 1

section .text
	global main

iterar:
	sub rsp, 8
	mov rbx, iterations
	add dword [rbx], 1

	; PARTE 1: CALCULAR O ERRO
	movsd xmm0, [setpoint]
	movsd xmm1, [atual]
	subsd xmm0, xmm1
	movsd [erro], xmm0

	; PARTE 2: CALCULAR A SAÍDA PROPORCIONAL
	movsd xmm2, [kp]
	mulsd xmm0, xmm2 ; xmm0 ARMAZENA A SAÍDA
	movsd [saida_P], xmm0

	; PARTE 3: CALCULAR A SAÍDA INTEGRATIVA
	movsd xmm0, [ki]
	movsd xmm1, [erro]
	movsd xmm2, [erro_acumulado]
	movsd xmm3, [d_t]
	mulsd xmm1, xmm3
	addsd xmm2, xmm1
	movsd [erro_acumulado], xmm2
	mulsd xmm2, xmm0
	movsd [saida_I], xmm2

	; PARTE 4: CALCULAR A SAÍDA DERIVATIVA
	movsd xmm0, [kd]
	movsd xmm1, [erro]
	movsd xmm2, [erro_anterior]
	movsd xmm3, [d_t]
	subsd xmm1, xmm2
	divsd xmm1, xmm3
	mulsd xmm1, xmm0
	movsd [saida_D], xmm1

	; PARTE 5: CALCULAR SAÍDA FINAL E ATUALIZAR POSIÇÃO ATUAL
	movsd xmm0, [d_t]
	movsd xmm1, [saida_P]
	movsd xmm2, [saida_I]
	movsd xmm3, [saida_D]
	addsd xmm1, xmm2
	addsd xmm1, xmm3
	movsd [saida], xmm1
	mulsd xmm0, xmm1
	movsd xmm4, [atual]
	addsd xmm4, xmm0
	movsd [atual], xmm4

	; PARTE 6: IMPRESSÃO DO STATUS ATUAL
	mov rdi, msg
	mov rsi, [rbx]
	mov rax, 6
	movsd xmm0, [erro]
	movsd xmm1, [saida]
	movsd xmm2, [saida_P]
	movsd xmm3, [saida_I]
	movsd xmm4, [saida_D]
	movsd xmm5, [atual]
	call printf
	xor rbx, rbx
	add rsp, 8
	movsd xmm0, [erro]
	movsd [erro_anterior], xmm0
	ret
main:
	sub rsp, 8

	; ALGORÍTMO:
	; 1: CALCULAR ERRO (m)
	; 2: CALCULAR SAÍDA (m/s)
	; 3: ATUALIZAR POSIÇÃO ATUAL (m)
	; 4: IMPRIMIR OS VALORES
	; 5: REPETIR ESSE ALGORÍTMO SE ERRO != 0

verificar:
	; CHAMAR A FUNÇÃO DE CÁLCULO
	call iterar

	movsd xmm0, [erro]
	pcmpeqd xmm1, xmm1
	psrlq xmm1, 1
	andpd xmm0, xmm1
	comisd xmm0, [tolerancia]
	ja verificar

final:
	mov rdi, success
	xor rax, rax
	call printf

	xor rax, rax
	add rsp, 8
	ret
