#ifndef USBCOMM_H_
#define USBCOMM_H_

uint8_t transmit_usb_packet(uint32_t* data, uint16_t data_len);
void process_and_transmit_buffer(uint8_t buffer_index, uint32_t* packet_counter);
void usb_transmit_task();
void check_and_send_chunks(void);
void process_and_transmit_chunk(uint8_t buffer_index, uint32_t start_idx, uint32_t chunk_size);
#endif /* BUFFER_H_ */
