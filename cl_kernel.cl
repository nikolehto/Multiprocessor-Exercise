void kernel resizeAndGreyScaleImg(global const unsigned char* img, global unsigned char* result_img, unsigned result_image_width, unsigned sampling_step, unsigned padding)
{
	const float r_con = 0.2126f, g_con = 0.7152f, b_con = 0.0722f;

	const int pixel_x_coordinate = get_global_id(0);
	const int pixel_y_coordinate = get_global_id(1);

	const int result_pixel_index = pixel_x_coordinate + (pixel_y_coordinate * result_image_width);
	
	// pixels above current index
	const int input_image_y_offset = result_image_width * pixel_y_coordinate * sampling_step * sampling_step * 4;
	// pixels on the row
	const int input_image_x_offset = pixel_x_coordinate * sampling_step * 4;

	const int input_image_index = input_image_y_offset + input_image_x_offset;
	const int paddingoffset = ((padding * (result_image_width + (2 * padding))) + padding) + (pixel_y_coordinate * 2 * padding);

	result_img[paddingoffset + result_pixel_index] = round(img[input_image_index] *r_con
		+ img[input_image_index + 1] * g_con
		+ img[input_image_index + 2] * b_con);
}

void kernel mean_calc(global const unsigned char* img, global unsigned char* result_img, unsigned image_width, unsigned image_height, int win_rad)
{
	unsigned int mean = 0;
	unsigned int value_count = (2 * win_rad + 1) * (2 * win_rad + 1);

	const int current_pixel_x_coordinate = get_global_id(0);
	const int current_pixel_y_coordinate = get_global_id(1);

	const int current_pixel_index = (current_pixel_y_coordinate * image_width) + current_pixel_x_coordinate;

	for (int win_y = -win_rad; win_y <= win_rad; win_y++)
	{
		const int window_y_pixel_coordinate = current_pixel_y_coordinate + win_y;

		for (int win_x = -win_rad; win_x <= win_rad; win_x++)
		{
			const int window_x_pixel_coordinate = current_pixel_x_coordinate + win_x;
		
			int const current_window_pixel_index = (window_y_pixel_coordinate * image_width) + window_x_pixel_coordinate;

			mean += img[current_window_pixel_index];
			value_count++;
		}
	}

	mean /= value_count;

	result_img[current_pixel_index] = (unsigned char) mean;
}

void kernel cross_check(global const unsigned char* r_img, global const unsigned char* l_img, global unsigned char* result_img, unsigned image_width, unsigned image_height, unsigned max_diff)
{
	const int img_index = get_global_id(0) + (get_global_id(1) * image_width);

	const int diff = l_img[img_index] - r_img[img_index];
	if (diff >= 0) // l_img is winner
	{
		if (diff <= max_diff)
		{
			result_img[img_index] = l_img[img_index];
		}
		else
		{
			result_img[img_index] = 0;
		}
	}
	else //  r_img is winner
	{
		if (-diff <= max_diff)
		{
			result_img[img_index] = r_img[img_index];
		}
		else
		{
			result_img[img_index] = 0;
		}
	}
}

void kernel zncc_calc(global const unsigned char* l_img, global const unsigned char* r_img, global const unsigned char* l_mean_img, global const unsigned char* r_mean_img, global unsigned char* disp_img, unsigned img_width, unsigned img_height, int win_rad, int max_disparity, float scale_factor)
{
	int min_disparity = 0;
	if (max_disparity < 0) // if max_disparity is negative swap min_disparity and max_disparity
	{
		min_disparity = max_disparity;
		max_disparity = 0;
	}
	
	const int current_pixel_x_coordinate = get_global_id(0);
	const int current_pixel_y_coordinate = get_global_id(1);

	const int pixel_index = current_pixel_x_coordinate + (current_pixel_y_coordinate * img_width);

	const int l_mean_value = l_mean_img[pixel_index];

	int winner_d_index = 0;
	//change to float
	float highest_correlation = 0.0f;

	for (int disp_x = min_disparity; disp_x< max_disparity; disp_x++)
	{
		float upper_sum = 0;
		float lower_sum_0 = 0;
		float lower_sum_1 = 0;

		const int r_mean_value = r_mean_img[pixel_index + disp_x];

		for (int win_y = -win_rad; win_y <= win_rad; win_y++)
		{
			const int window_y_pixel_index = ((current_pixel_y_coordinate + win_y) * img_width) + current_pixel_x_coordinate;

			for (int win_x = -win_rad; win_x <= win_rad; win_x++)
			{
				const int left_pixel_val_diff_from_avg = l_img[window_y_pixel_index + win_x] - l_mean_value;
				const int right_pixel_val_diff_from_avg = r_img[window_y_pixel_index + win_x + disp_x] - r_mean_value;
				upper_sum += left_pixel_val_diff_from_avg * right_pixel_val_diff_from_avg;
				lower_sum_0 += left_pixel_val_diff_from_avg * left_pixel_val_diff_from_avg;
				lower_sum_1 += right_pixel_val_diff_from_avg * right_pixel_val_diff_from_avg;
			}
		}

		const float lower_value = sqrt(lower_sum_0) * sqrt(lower_sum_1);
		if (lower_value != 0.0f)
		{
			//change to float
			const float zncc_value = upper_sum / lower_value;
			if (zncc_value > highest_correlation)
			{
				highest_correlation = zncc_value;
				winner_d_index = disp_x;
			}
		}
	}
	disp_img[pixel_index] = round(winner_d_index * scale_factor);
}

void kernel occlusion_filling(global unsigned char* post_img, unsigned img_width, unsigned img_height, int window_radius) {
	//return;
	const int pixel_index = get_global_id(0) + (get_global_id(1) * img_width);

	if (post_img[pixel_index] == 0)
	{
		//const int img_size = img_width*img_height;
		//calculates mean value from window pixels but ignoring zero valued pixels and using also values that are calculated previous rounds
		//window_radius = 1 => 9 tiles
		//window_radius = 2 => 25 tiles
		//window_radius = 3 => 49 tiles
		//window_radius = 4 => 81 tiles

		int window_sum = 0;
		int window_valid_pixels_count = 0;

		for (int window_y = -window_radius; window_y <= window_radius; window_y++)
		{
			const int window_y_pixel_index = pixel_index + (window_y * img_width);

			for (int window_x = -window_radius; window_x <= window_radius; window_x++)
			{

				const int current_pixel_index = window_y_pixel_index + window_x;

				if (post_img[current_pixel_index] != 0)
				{
					window_sum = window_sum + post_img[current_pixel_index];
					window_valid_pixels_count++;
				}
			}
		}
		//Calculate mean and insert it to result picture	
		if (window_valid_pixels_count > 0)
		{
			int mean = window_sum / window_valid_pixels_count;
			post_img[pixel_index] = mean;
		}
		else
		{
			post_img[pixel_index] = 0;
		}
		
	}
}