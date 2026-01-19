<template>
	<Teleport to="body">
		<TransitionGroup name="toast">
			<div
				v-for="notification in notifications"
				:key="notification.id"
				class="message-notification"
				:class="{
					'notification-global': notification.type === 'general',
					'notification-personal': notification.type === 'specific',
				}"
				:style="{
					top: `${20 + notification.index * 110}px`,
				}"
				@click="handleClick(notification.id)">
				<div class="message-icon">
					<img v-if="notification.senderImage" :src="notification.senderImage" :alt="notification.senderName" class="sender-avatar" />
					<div v-else class="sender-avatar-fallback">
						<span>{{ getInitials(notification.senderName) }}</span>
					</div>
				</div>

				<div class="message-content">
					<div class="message-header">
						<span class="message-badge" :class="notification.type">
							{{ notification.type === 'general' ? '📢 Global' : '📩 Personal' }}
						</span>
						<span class="message-time">{{ getTimeAgo(notification.createdAt) }}</span>
					</div>
					<div class="message-sender">{{ notification.senderName }}</div>
					<div class="message-text">{{ truncateMessage(notification.message) }}</div>
				</div>

				<button class="notification-close" @click.stop="handleClose(notification.id)" aria-label="Cerrar notificación">×</button>
			</div>
		</TransitionGroup>
	</Teleport>
</template>

<script setup>
	import { computed } from 'vue';

	const props = defineProps({
		notifications: {
			type: Array,
			required: true,
		},
	});

	const emit = defineEmits(['click', 'close']);

	function getInitials(name) {
		if (!name) return '?';
		const parts = name.trim().split(' ');
		if (parts.length >= 2) {
			return (parts[0][0] + parts[1][0]).toUpperCase();
		}
		return name.substring(0, 2).toUpperCase();
	}

	function truncateMessage(message, maxLength = 80) {
		if (!message) return '';
		if (message.length <= maxLength) return message;
		return message.substring(0, maxLength) + '...';
	}

	function getTimeAgo(dateString) {
		if (!dateString) return '';
		const date = new Date(dateString);
		const now = new Date();
		const diffMs = now - date;
		const diffSecs = Math.floor(diffMs / 1000);
		const diffMins = Math.floor(diffMs / 60000);

		if (diffSecs < 10) return 'Ahora';
		if (diffSecs < 60) return `Hace ${diffSecs}s`;
		if (diffMins < 60) return `Hace ${diffMins}m`;

		const diffHours = Math.floor(diffMs / 3600000);
		if (diffHours < 24) return `Hace ${diffHours}h`;

		const diffDays = Math.floor(diffMs / 86400000);
		return `Hace ${diffDays}d`;
	}

	function handleClick(notificationId) {
		emit('click', notificationId);
	}

	function handleClose(notificationId) {
		emit('close', notificationId);
	}
</script>

<style scoped>
	.message-notification {
		position: fixed;
		right: 20px;
		background: linear-gradient(135deg, rgba(10, 0, 32, 0.98) 0%, rgba(0, 0, 0, 0.98) 100%);
		border: 3px solid rgba(0, 255, 194, 0.6);
		border-radius: 12px;
		padding: 16px 20px;
		min-width: 380px;
		max-width: 480px;
		z-index: 9999;
		display: flex;
		align-items: flex-start;
		gap: 14px;
		animation: slideIn 0.4s cubic-bezier(0.4, 0, 0.2, 1);
		backdrop-filter: blur(12px);
		box-shadow:
			0 8px 32px rgba(0, 0, 0, 0.7),
			0 0 20px rgba(0, 255, 194, 0.3),
			inset 0 0 15px rgba(0, 255, 194, 0.1);
		cursor: pointer;
		transition: all 0.2s ease;
	}

	.message-notification:hover {
		transform: translateX(-4px);
		box-shadow:
			0 12px 40px rgba(0, 0, 0, 0.8),
			0 0 30px rgba(0, 255, 194, 0.5),
			inset 0 0 20px rgba(0, 255, 194, 0.15);
	}

	.notification-global {
		border-color: rgba(0, 255, 194, 0.7);
	}

	.notification-personal {
		border-color: rgba(255, 218, 121, 0.7);
		box-shadow:
			0 8px 32px rgba(0, 0, 0, 0.7),
			0 0 20px rgba(255, 218, 121, 0.3),
			inset 0 0 15px rgba(255, 218, 121, 0.1);
	}

	.notification-personal:hover {
		box-shadow:
			0 12px 40px rgba(0, 0, 0, 0.8),
			0 0 30px rgba(255, 218, 121, 0.5),
			inset 0 0 20px rgba(255, 218, 121, 0.15);
	}

	@keyframes slideIn {
		from {
			transform: translateX(500px);
			opacity: 0;
		}
		to {
			transform: translateX(0);
			opacity: 1;
		}
	}

	.message-icon {
		flex-shrink: 0;
		width: 56px;
		height: 56px;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.sender-avatar {
		width: 56px;
		height: 56px;
		border-radius: 10px;
		border: 2px solid rgba(0, 255, 194, 0.6);
		object-fit: cover;
		image-rendering: pixelated;
		box-shadow: 0 0 15px rgba(0, 255, 194, 0.4);
		animation: avatarPulse 2s ease-in-out infinite;
	}

	.notification-personal .sender-avatar {
		border-color: rgba(255, 218, 121, 0.6);
		box-shadow: 0 0 15px rgba(255, 218, 121, 0.4);
	}

	.sender-avatar-fallback {
		width: 56px;
		height: 56px;
		border-radius: 10px;
		border: 2px solid rgba(0, 255, 194, 0.6);
		background: linear-gradient(135deg, rgba(0, 255, 194, 0.2) 0%, rgba(0, 255, 194, 0.05) 100%);
		display: flex;
		align-items: center;
		justify-content: center;
		font-family: 'Press Start 2P', monospace;
		font-size: 0.9rem;
		color: #00ffc2;
		text-shadow: 0 0 10px rgba(0, 255, 194, 0.8);
		box-shadow: 0 0 15px rgba(0, 255, 194, 0.4);
		animation: avatarPulse 2s ease-in-out infinite;
	}

	.notification-personal .sender-avatar-fallback {
		border-color: rgba(255, 218, 121, 0.6);
		background: linear-gradient(135deg, rgba(255, 218, 121, 0.2) 0%, rgba(255, 218, 121, 0.05) 100%);
		color: #ffda79;
		text-shadow: 0 0 10px rgba(255, 218, 121, 0.8);
		box-shadow: 0 0 15px rgba(255, 218, 121, 0.4);
	}

	@keyframes avatarPulse {
		0%,
		100% {
			box-shadow: 0 0 15px rgba(0, 255, 194, 0.4);
		}
		50% {
			box-shadow: 0 0 25px rgba(0, 255, 194, 0.7);
		}
	}

	.message-content {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.message-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 10px;
	}

	.message-badge {
		font-family: 'Press Start 2P', monospace;
		font-size: 0.5rem;
		padding: 4px 8px;
		border-radius: 6px;
		text-transform: uppercase;
		letter-spacing: 0.5px;
	}

	.message-badge.general {
		background: rgba(0, 255, 194, 0.2);
		color: #00ffc2;
		border: 1px solid rgba(0, 255, 194, 0.4);
		box-shadow: 0 0 8px rgba(0, 255, 194, 0.3);
	}

	.message-badge.specific {
		background: rgba(255, 218, 121, 0.2);
		color: #ffda79;
		border: 1px solid rgba(255, 218, 121, 0.4);
		box-shadow: 0 0 8px rgba(255, 218, 121, 0.3);
	}

	.message-time {
		font-family: 'Press Start 2P', monospace;
		font-size: 0.45rem;
		color: rgba(255, 255, 255, 0.5);
	}

	.message-sender {
		font-family: 'Press Start 2P', monospace;
		font-size: 0.65rem;
		color: #ffffff;
		text-shadow: 0 0 10px rgba(255, 255, 255, 0.5);
		letter-spacing: 0.5px;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.message-text {
		font-family: 'Press Start 2P', monospace;
		font-size: 0.55rem;
		color: rgba(255, 255, 255, 0.85);
		line-height: 1.5;
		word-wrap: break-word;
		display: -webkit-box;
		-webkit-line-clamp: 2;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}

	.notification-close {
		position: absolute;
		top: 8px;
		right: 8px;
		width: 28px;
		height: 28px;
		border-radius: 6px;
		border: 2px solid rgba(247, 65, 143, 0.5);
		background: rgba(0, 0, 0, 0.6);
		color: #f7418f;
		font-size: 1.4rem;
		line-height: 1;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.2s ease;
		font-family: monospace;
		padding: 0;
	}

	.notification-close:hover {
		background: rgba(247, 65, 143, 0.2);
		border-color: rgba(247, 65, 143, 0.8);
		transform: scale(1.1);
	}

	.notification-close:active {
		transform: scale(0.95);
	}

	/* Transiciones del grupo */
	.toast-enter-active {
		transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
	}

	.toast-leave-active {
		transition: all 0.3s ease-in;
	}

	.toast-enter-from {
		transform: translateX(500px);
		opacity: 0;
	}

	.toast-leave-to {
		transform: translateX(500px) scale(0.95);
		opacity: 0;
	}

	.toast-move {
		transition: all 0.3s ease;
	}

	/* Responsive */
	@media (max-width: 640px) {
		.message-notification {
			right: 10px;
			left: 10px;
			min-width: auto;
			max-width: none;
			padding: 14px 16px;
		}

		.message-icon {
			width: 48px;
			height: 48px;
		}

		.sender-avatar,
		.sender-avatar-fallback {
			width: 48px;
			height: 48px;
		}

		.message-sender {
			font-size: 0.6rem;
		}

		.message-text {
			font-size: 0.5rem;
		}
	}
</style>
