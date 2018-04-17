void kernel simple_add(global const int* A, global const int* B, global int* C)
{       
    C[get_global_id(0)]=A[get_global_id(0)]+B[get_global_id(0)];                 
}

void kernel resizeAndGreyScaleImg(global const unsigned char* img, global unsigned char* result_img, unsigned result_image_width, unsigned sampling_step)
{
	//const unsigned char r_con = 0.2126 * 255, g_con = 0.7152 * 255, b_con = 0.0722 * 255; // TODO (for performance somehow use char? maybe output should be shifted or something) 
	const float r_con = 0.2126f, g_con = 0.7152f, b_con = 0.0722f;

	const int result_pixel_index = get_global_id(0);
	
	// pixels above current index
	const int input_image_y_offset = (result_pixel_index / result_image_width) * sampling_step * sampling_step * 4 * result_image_width;
	// pixels on the row
	const int input_image_x_offset = (result_pixel_index % result_image_width) * sampling_step * 4;
	// sum
	const int input_image_index = input_image_y_offset + input_image_x_offset;

	result_img[result_pixel_index] = round(img[input_image_index] *r_con
		+ img[input_image_index + 1] * g_con
		+ img[input_image_index + 2] * b_con);
}

void kernel mean_calc(global const unsigned char* img, global unsigned char* result_img, unsigned image_width, unsigned image_height, unsigned win_rad)
{

	//TODO: This calculus gets performed everytime, and its waste of time
	//const int win_rad_x = (win_size - 1) / 2;
	//const int win_rad_y = (win_size - 1) / 2;

	const int win_radius = win_rad;


	//const int img_size = image_width * image_height; //TODO: useless

	unsigned int mean = 0;
	unsigned int value_count = 0;

	//const int current_pixel_index = get_global_id(0) * ;

	const int current_pixel_x_coordinate = get_global_id(0);
	const int current_pixel_y_coordinate = get_global_id(1);

	const int current_pixel_index = (current_pixel_y_coordinate * image_width) + current_pixel_x_coordinate;

	//Removed costly modulo calculation which was used earlier


	for (int win_y = -win_radius; win_y <= win_radius; win_y++)
	{
		const int window_y_pixel_coordinate = current_pixel_y_coordinate + win_y;
		if (window_y_pixel_coordinate < 0 || window_y_pixel_coordinate >= image_height)
		{
			continue;
		}

		for (int win_x = -win_radius; win_x <= win_radius; win_x++)
		{
			const int window_x_pixel_coordinate = current_pixel_x_coordinate + win_x;
			if (window_x_pixel_coordinate < 0 || (window_x_pixel_coordinate >= image_width))
			{
				continue;
			}

			int const current_window_pixel_index = (window_y_pixel_coordinate * image_height) + window_x_pixel_coordinate;

			mean += img[current_window_pixel_index];
			value_count++;
		}
	}

	mean /= value_count;

	result_img[current_pixel_index] = (unsigned char) mean;
}

void kernel cross_check(global const unsigned char* r_img, global const unsigned char* l_img, global unsigned char* result_img, unsigned image_width, unsigned image_height, unsigned max_diff)
{
	const int img_index = get_global_id(0);
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

void kernel zncc_calc(global const unsigned char* l_img, global const unsigned char* r_img, global const unsigned char* l_mean_img, global const unsigned char* r_mean_img, global unsigned char* disp_img, unsigned img_width, unsigned img_height, unsigned win_size, int max_disparity)
{
	//calculating this on every time, dead weight
	const int win_rad_x = (win_size - 1) / 2;
	const int win_rad_y = (win_size - 1) / 2;

	const int img_size = img_width*img_height;

	int min_disparity = 0;
	const float scale_factor = (float)255 / (max_disparity - min_disparity); //scale factor may be negative, at least in c++ its ok to save negative values to unsigned (later scale_factor*d_index is casted to unsigned char)
	if (max_disparity < 0) // if max_disparity is negative swap min_disparity and max_disparity
	{
		min_disparity = max_disparity;
		max_disparity = 0;
	}

	const int pixel_index = get_global_id(0);


	const int pixel_x_coordinate = pixel_index % img_width;

	const int l_mean_value = l_mean_img[pixel_index];

	int winner_d_index = 0;
	//change to float
	float highest_correlation = 0.0f;

	for (int disp_x = min_disparity; disp_x< max_disparity; disp_x++)
	{
		if (pixel_x_coordinate + disp_x < 0 || pixel_x_coordinate + disp_x >= img_width)
		{
			continue;
		}

		float upper_sum = 0;
		float lower_sum_0 = 0;
		float lower_sum_1 = 0;

		const int r_mean_value = r_mean_img[pixel_index + disp_x];

		for (int win_y = -win_rad_y; win_y <= win_rad_y; win_y++)
		{
			//const int y_index = img_y + win_y;
			const int window_y_pixel_index = pixel_index + (win_y * img_width);
			if (window_y_pixel_index < 0 || window_y_pixel_index >= img_size)
			{
				continue;
			}

			for (int win_x = -win_rad_x; win_x <= win_rad_x; win_x++)
			{
				const int x_index = pixel_x_coordinate + win_x;
				const int x_disp_index = pixel_x_coordinate + win_x + disp_x;
				if (x_disp_index < 0
					|| x_disp_index >= img_width
					|| x_index < 0
					|| x_index >= img_width)
				{
					// how to deal with edges, if continue does it have any functionality or misfunctionality
					continue;
				}

				const int left_pixel_val_diff_from_avg = l_img[window_y_pixel_index + win_x] - l_mean_value;
				const int right_pixel_val_diff_from_avg = r_img[window_y_pixel_index + win_x + disp_x] - r_mean_value;
				upper_sum += left_pixel_val_diff_from_avg * right_pixel_val_diff_from_avg;
				lower_sum_0 += left_pixel_val_diff_from_avg * left_pixel_val_diff_from_avg;
				lower_sum_1 += right_pixel_val_diff_from_avg * right_pixel_val_diff_from_avg;
			}
		}

		const float lower_value = (sqrt(lower_sum_0) * sqrt(lower_sum_1));
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

	const int pixel_index = get_global_id(0);

	if (post_img[pixel_index] == 0)
	{
		const int img_size = img_width*img_height;
		//calculates mean value from window pixels but ignoring zero valued pixels and using also values that are calculated previous rounds
		//window_radius = 1 => 9 tiles
		//window_radius = 2 => 25 tiles
		//window_radius = 3 => 49 tiles
		//window_radius = 4 => 81 tiles

		int window_sum = 0;
		int window_valid_pixels_count = 0;

		const int pixel_x_coordinate = pixel_index % img_width;

		for (int window_y = -window_radius; window_y <= window_radius; window_y++)
		{
			const int window_y_pixel_index = pixel_index + (window_y * img_width);
			if (window_y_pixel_index < 0)
			{
				//not valid
				continue;
			}

			if ((window_y_pixel_index) >= img_size)
			{
				//not valid
				continue;
			}

			for (int window_x = -window_radius; window_x <= window_radius; window_x++)
			{
				//check if valid window pixel
				if ((pixel_x_coordinate + window_x) < 0)
				{
					//not valid
					continue;
				}

				if ((pixel_x_coordinate + window_x) >= img_width)
				{
					//not valid
					continue;
				}

				//pixel location is valid

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