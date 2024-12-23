from flask import Flask, render_template, request, jsonify, url_for, redirect, send_file, Response
import requests
import json
from bs4 import BeautifulSoup
from flask_caching import Cache
import time
from datetime import datetime
import io
import zipfile

app = Flask(__name__)

# Konfigurasi cache
cache = Cache(app, config={'CACHE_TYPE': 'SimpleCache', 'CACHE_DEFAULT_TIMEOUT': 300})

# Fungsi helper untuk menghapus cache
def clear_manga_cache():
    """Hapus cache untuk semua fungsi scraping manga"""
    cache.delete_memoized(scrape_komik)
    cache.delete_memoized(scrape_detail_komik)
    cache.delete_memoized(scrape_chapter)

# Fungsi untuk format timestamp
def format_time_ago(timestamp):
    try:
        if isinstance(timestamp, str):
            dt = datetime.strptime(timestamp, '%Y-%m-%d %H:%M:%S')
            timestamp = dt.timestamp()
        
        current_time = time.time()
        time_diff = current_time - float(timestamp)
        
        if time_diff < 60:
            return "Baru saja"
        elif time_diff < 3600:
            minutes = int(time_diff / 60)
            return f"{minutes} menit yang lalu"
        elif time_diff < 86400:
            hours = int(time_diff / 3600)
            return f"{hours} jam yang lalu"
        else:
            days = int(time_diff / 86400)
            return f"{days} hari yang lalu"
    except Exception as e:
        print(f"Error formatting time: {str(e)}")
        return timestamp

def create_cbz_from_images(images, manga_title, chapter_title):
    # Buat ZIP dalam memory
    zip_buffer = io.BytesIO()
    
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as cbz:
        for idx, img_url in enumerate(images, start=1):
            try:
                # Download gambar
                response = requests.get(img_url)
                if response.status_code == 200:
                    # Simpan gambar dengan nama yang terurut
                    image_ext = img_url.split('.')[-1].split('?')[0]
                    image_name = f'{idx:03d}.{image_ext}'
                    cbz.writestr(image_name, response.content)
            except Exception as e:
                print(f"Error downloading image {idx}: {str(e)}")
                continue

    zip_buffer.seek(0)
    return zip_buffer
    
# Fungsi scraping komik
@cache.memoize(timeout=300)
def scrape_komik(url, force_refresh=False):
    if force_refresh:
        cache.delete_memoized(scrape_komik, url)
    
    response = requests.get(url)
    response.encoding = 'utf-8'  
    soup = BeautifulSoup(response.text, 'html.parser')

    komik_data = []
    komiks = soup.select('.list-update_item')

    for komik in komiks:
        title = komik.select_one('.title').text.strip()
        full_link = komik.select_one('a')['href']
        
        # Format link
        if 'komikcast.bz' in full_link:
            relative_link = full_link.split('komikcast.bz/')[-1]
        else:
            relative_link = full_link.lstrip('/')
        
        relative_link = relative_link.replace('komik/', '')
        while '//' in relative_link:
            relative_link = relative_link.replace('//', '/')
        relative_link = relative_link.rstrip('/')
            
        image = komik.select_one('img')['src']
        chapter = komik.select_one('.chapter').text.strip() if komik.select_one('.chapter') else "N/A"
        score = komik.select_one('.numscore').text.strip() if komik.select_one('.numscore') else "N/A"
        time_elem = komik.select_one('.timeago')
        update_time = time_elem['datetime'] if time_elem else None
        
        types = komik.select_one('.type').text.strip() if komik.select_one('.type') else "N/A"
        status = komik.select_one('.status').text.strip() if komik.select_one('.status') else "N/A"

        komik_data.append({
            'title': title,
            'link': relative_link,
            'image': image,
            'chapter': chapter,
            'score': score,
            'update_time': update_time,
            'type': types,
            'status': status
        })

    next_page = soup.select_one('a.next.page-numbers')
    next_page_url = next_page['href'] if next_page else None

    return komik_data, next_page_url
    
# Fungsi pencarian komik
@cache.memoize(timeout=300)
def search_komik(query):
    search_url = f"https://komikcast.bz/?s={query}"
    response = requests.get(search_url)
    response.encoding = 'utf-8'
    soup = BeautifulSoup(response.text, 'html.parser')
    
    komik_data = []
    komiks = soup.select('.list-update_item')
    
    for komik in komiks:
        title = komik.select_one('.title').text.strip()
        full_link = komik.select_one('a')['href']
        
        if 'komikcast.bz' in full_link:
            relative_link = full_link.split('komikcast.bz/')[-1]
        else:
            relative_link = full_link.lstrip('/')
        
        relative_link = relative_link.replace('komik/', '')
        while '//' in relative_link:
            relative_link = relative_link.replace('//', '/')
        relative_link = relative_link.rstrip('/')
        
        image = komik.select_one('img')['src']
        chapter = komik.select_one('.chapter').text.strip() if komik.select_one('.chapter') else "N/A"
        score = komik.select_one('.numscore').text.strip() if komik.select_one('.numscore') else "N/A"
        time_elem = komik.select_one('.timeago')
        update_time = time_elem['datetime'] if time_elem else None
        
        types = komik.select_one('.type').text.strip() if komik.select_one('.type') else "N/A"
        status = komik.select_one('.status').text.strip() if komik.select_one('.status') else "N/A"
        
        komik_data.append({
            'title': title,
            'link': relative_link,
            'image': image,
            'chapter': chapter,
            'score': score,
            'update_time': update_time,
            'type': types,
            'status': status
        })
    
    return komik_data

# Fungsi scraping detail komik
@cache.memoize(timeout=300)
def scrape_detail_komik(url, force_refresh=False):
    if force_refresh:
        cache.delete_memoized(scrape_detail_komik, url)
    
    try:
        response = requests.get(url)
        response.encoding = 'utf-8'
        soup = BeautifulSoup(response.text, 'html.parser')

        # Data dasar
        thumbnail_elem = soup.select_one('.komik_info-content-thumbnail img')
        thumbnail = thumbnail_elem['src'] if thumbnail_elem else ''
        
        title_elem = soup.select_one('.komik_info-content-body-title')
        title = title_elem.text.strip() if title_elem else ''
        
        native_title_elem = soup.select_one('.komik_info-content-native')
        native_title = native_title_elem.text.strip() if native_title_elem else ''

        # Synopsis
        synopsis_elem = soup.select_one('.komik_info-description-sinopsis')
        synopsis = synopsis_elem.text.strip() if synopsis_elem else ''
        
        # Genres
        genres = [genre.text for genre in soup.select('.komik_info-content-genre .genre-item')]
        
        # Info detail
        info_elements = soup.select('.komik_info-content-meta span')
        release = ''
        author = ''
        status = ''
        total_chapter = ''
        
        for info in info_elements:
            text = info.text.strip()
            if 'Released:' in text:
                release = text.replace('Released:', '').strip()
            elif 'Author:' in text:
                author = text.replace('Author:', '').strip()
            elif 'Status:' in text:
                status = text.replace('Status:', '').strip()
            elif 'Total Chapter:' in text:
                total_chapter = text.replace('Total Chapter:', '').strip()

        type_elem = soup.select_one('.komik_info-content-info-type a')
        komik_type = type_elem.text.strip() if type_elem else ''

        updated_elem = soup.select_one('.komik_info-content-update time')
        updated_on = updated_elem['datetime'] if updated_elem else ''

        rating_elem = soup.select_one('.data-rating')
        rating = rating_elem['data-ratingkomik'] if rating_elem else '0'

        # Chapter list
        chapters = []
        chapter_items = soup.select('.komik_info-chapters-item')
        for chapter in chapter_items:
            chapter_link_elem = chapter.select_one('.chapter-link-item')
            if chapter_link_elem:
                full_chapter_link = chapter_link_elem['href']
                relative_chapter_link = full_chapter_link.replace('https://komikcast.bz', '')
                if not relative_chapter_link.startswith('/'):
                    relative_chapter_link = '/' + relative_chapter_link
                
                time_elem = chapter.select_one('.chapter-link-time')
                update_time = time_elem.text.strip() if time_elem else ''
                
                chapters.append({
                    'title': chapter_link_elem.text.strip(),
                    'link': relative_chapter_link,
                    'time': update_time
                })

        return {
            'thumbnail': thumbnail,
            'title': title,
            'native_title': native_title,
            'synopsis': synopsis,
            'genres': genres,
            'release': release,
            'author': author,
            'status': status,
            'type': komik_type,
            'total_chapter': total_chapter,
            'updated_on': updated_on,
            'rating': rating,
            'chapters': chapters
        }
    except Exception as e:
        print(f"Error scraping detail: {str(e)}")
        return None

# Fungsi scraping chapter
@cache.memoize(timeout=300)
def scrape_chapter(url, force_refresh=False):
    if force_refresh:
        cache.delete_memoized(scrape_chapter, url)
    
    try:
        response = requests.get(url)
        response.encoding = 'utf-8'
        soup = BeautifulSoup(response.content, 'html.parser')

        # Ambil judul chapter
        title_elem = soup.select_one('.chapter_headpost h1')
        title = title_elem.text.strip() if title_elem else ''

        # Ambil navigasi chapter
        chapter_nav = soup.select_one('.chapter_nav-control')
        chapter_options = []
        
        if chapter_nav:
            select_elem = chapter_nav.select_one('select#slch')
            if select_elem:
                for option in select_elem.find_all('option'):
                    full_link = option['value']
                    relative_link = full_link.replace('https://komikcast.bz', '')
                    if not relative_link.startswith('/'):
                        relative_link = '/' + relative_link

                    chapter_options.append({
                        'title': option.text.strip(),
                        'link': relative_link,
                        'selected': 'selected' in option.attrs
                    })

        # Ambil link previous dan next chapter
        prev_chapter = soup.select_one('a[rel="prev"]')
        next_chapter = soup.select_one('a[rel="next"]')
        
        relative_prev_link = prev_chapter['href'].replace('https://komikcast.bz', '') if prev_chapter else None
        relative_next_link = next_chapter['href'].replace('https://komikcast.bz', '') if next_chapter else None

        # Ambil gambar chapter
        images = []
        for img in soup.find_all('img', class_='alignnone'):
            if img.get('src'):
                images.append(img['src'])
            elif img.get('data-src'):
                images.append(img['data-src'])

        return {
            'title': title,
            'chapter_options': chapter_options,
            'prev_chapter': relative_prev_link,
            'next_chapter': relative_next_link,
            'images': images
        }
    except Exception as e:
        print(f"Error scraping chapter: {str(e)}")
        return None

# Routes
@app.route('/')
def home():
    force_refresh = request.args.get('refresh', '0') == '1'
    
    try:
        popular_url = "https://komikcast.bz/daftar-komik/?status=&type=&orderby=popular"
        popular_data, _ = scrape_komik(popular_url, force_refresh)
        
        latest_url = "https://komikcast.bz/daftar-komik/?orderby=update"
        latest_data, _ = scrape_komik(latest_url, force_refresh)
        
        featured_data = popular_data[:6] if popular_data else []
        
        return render_template(
            'home.html',
            featured_manga=featured_data,
            latest_manga=latest_data[:12] if latest_data else [],
            popular_manga=popular_data[:12] if popular_data else [],
            format_time_ago=format_time_ago
        )
    except Exception as e:
        app.logger.error(f"Home page error: {str(e)}")
        return render_template('error.html', error="Terjadi kesalahan saat memuat halaman")

# Rute untuk pencarian komik
@app.route('/search')
def search():
    query = request.args.get('query', '')
    if query:
        komik_data = search_komik(query)
        return render_template('search.html', komik_data=komik_data, query=query, format_time_ago=format_time_ago)
    else:
        return redirect(url_for('home'))
        
@app.route('/popular')
def popular():
    force_refresh = request.args.get('refresh', '0') == '1'
    page = request.args.get('page', 1, type=int)
    items_per_page = 24
    
    url = f"https://komikcast.bz/daftar-komik/?status=&type=&orderby=popular&page={page}"
    komik_data, next_page = scrape_komik(url, force_refresh)
    
    # Pagination
    start_idx = (page - 1) * items_per_page
    end_idx = start_idx + items_per_page
    paginated_komik = komik_data[start_idx:end_idx]
    has_next = len(komik_data) > end_idx
    
    return render_template(
        'popular.html',
        komik_data=paginated_komik,
        current_page=page,
        has_next=has_next,
        format_time_ago=format_time_ago
    )

@app.route('/latest')
def latest():
    force_refresh = request.args.get('refresh', '0') == '1'
    page = request.args.get('page', 1, type=int)
    items_per_page = 24
    
    url = f"https://komikcast.bz/daftar-komik/?sortby=update&page={page}"
    komik_data, next_page = scrape_komik(url, force_refresh)
    
    # Pagination
    start_idx = (page - 1) * items_per_page
    end_idx = start_idx + items_per_page
    paginated_komik = komik_data[start_idx:end_idx]
    has_next = len(komik_data) > end_idx
    
    return render_template(
        'latest.html',
        komik_data=paginated_komik,
        current_page=page,
        has_next=has_next,
        format_time_ago=format_time_ago
    )

@app.route('/detail/<path:url>')
def detail(url):
    force_refresh = request.args.get('refresh', '0') == '1'
    
    # Logging untuk debug
    app.logger.info(f"Original URL: {url}")
    
    # Bersihkan URL
    url = url.strip('/')
    if not url.startswith('komik/'):
        url = f"komik/{url}"
    
    # Logging URL final
    app.logger.info(f"Final URL: {url}")
    
    komik_url = f"https://komikcast.bz/{url}"
    app.logger.info(f"Full URL: {komik_url}")
    
    komik_detail = scrape_detail_komik(komik_url, force_refresh)
    
    if komik_detail is None:
        app.logger.error(f"Failed to fetch detail for URL: {komik_url}")
        return render_template('error.html', error_message="Komik tidak ditemukan"), 404
    
    return render_template(
        'detail.html',
        komik_detail=komik_detail,
        format_time_ago=format_time_ago
    )

@app.route('/chapter/<path:url>')
def chapter(url):
    force_refresh = request.args.get('refresh', '0') == '1'
    
    try:
        if not url.startswith('/'):
            url = '/' + url
        
        chapter_url = f"https://komikcast.bz{url}"
        chapter_data = scrape_chapter(chapter_url, force_refresh)
        
        if chapter_data is None:
            return render_template('error.html', error_message="Chapter tidak ditemukan"), 404
            
        return render_template('chapter.html', chapter_data=chapter_data)
    except Exception as e:
        print(f"Error in chapter route: {str(e)}")
        return render_template('error.html', error_message="Terjadi kesalahan saat memuat chapter"), 500

@app.route('/favorites')
def favorites():
    return render_template('favorites.html', format_time_ago=format_time_ago)

@app.route('/history')
def history():
    return render_template('history.html', format_time_ago=format_time_ago)

@app.route('/refresh')
def refresh_data():
    clear_manga_cache()
    return redirect(url_for('home'))

# Route untuk download single chapter
@app.route('/download/chapter/<path:url>')
def download_chapter(url):
    try:
        if not url.startswith('/'):
            url = '/' + url
        
        chapter_url = f"https://komikcast.bz{url}"
        chapter_data = scrape_chapter(chapter_url)
        
        if chapter_data is None:
            return "Chapter tidak ditemukan", 404
            
        # Buat CBZ
        cbz_buffer = create_cbz_from_images(
            chapter_data['images'],
            chapter_data['title'],
            chapter_data['title']
        )
        
        # Buat nama file yang aman
        safe_filename = "".join(x for x in chapter_data['title'] if x.isalnum() or x in (' ', '-', '_'))
        filename = f"{safe_filename}.cbz"
        
        return send_file(
            cbz_buffer,
            as_attachment=True,
            download_name=filename,
            mimetype='application/x-cbz'
        )
    except Exception as e:
        return f"Error: {str(e)}", 500

# Route untuk download batch chapter
@app.route('/download/batch/<path:url>')
def download_batch(url):
    try:
        # Bersihkan URL
        url = url.strip('/')
        if not url.startswith('komik/'):
            url = f"komik/{url}"
        
        komik_url = f"https://komikcast.bz/{url}"
        komik_detail = scrape_detail_komik(komik_url)
        
        if komik_detail is None:
            return "Komik tidak ditemukan", 404
        
        # Ambil chapter yang dipilih dari parameter
        selected_chapters = request.args.getlist('chapters')
        chapters_to_download = [ch for ch in komik_detail['chapters'] 
                              if ch['link'] in selected_chapters]
        
        if not chapters_to_download:
            return "Tidak ada chapter yang dipilih", 400
            
        # Buat ZIP untuk semua chapter
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as batch_zip:
            for chapter in chapters_to_download:
                try:
                    chapter_data = scrape_chapter(f"https://komikcast.bz{chapter['link']}")
                    if chapter_data and chapter_data['images']:
                        # Buat CBZ untuk chapter ini
                        chapter_buffer = create_cbz_from_images(
                            chapter_data['images'],
                            komik_detail['title'],
                            chapter['title']
                        )
                        # Tambahkan ke batch ZIP
                        safe_chapter_name = "".join(x for x in chapter['title'] 
                                                  if x.isalnum() or x in (' ', '-', '_'))
                        batch_zip.writestr(f"{safe_chapter_name}.cbz", 
                                         chapter_buffer.getvalue())
                except Exception as e:
                    print(f"Error processing chapter {chapter['title']}: {str(e)}")
                    continue
        
        zip_buffer.seek(0)
        safe_manga_name = "".join(x for x in komik_detail['title'] 
                                if x.isalnum() or x in (' ', '-', '_'))
        filename = f"{safe_manga_name}_batch.zip"
        
        return send_file(
            zip_buffer,
            as_attachment=True,
            download_name=filename,
            mimetype='application/zip'
        )
    except Exception as e:
        return f"Error: {str(e)}", 500
        
# Error handlers
@app.errorhandler(404)
def page_not_found(e):
    return render_template('error.html', error_message="Halaman tidak ditemukan"), 404

@app.errorhandler(500)
def internal_server_error(e):
    return render_template('error.html', error_message="Terjadi kesalahan internal server"), 500

@app.route('/download/batch/')
def download_batch_new():
    chapters = request.args.getlist('chapters')
    
    # Create a response with SSE (Server-Sent Events) for progress updates
    def generate():
        try:
            total_chapters = len(chapters)
            for i, chapter in enumerate(chapters, 1):
                # Your existing download logic here
                # ...
                
                # Send progress update
                progress = (i / total_chapters) * 100
                yield f"data: {{'progress': {progress}, 'chapter': '{chapter}'}}\n\n"
                
            yield "data: {'status': 'complete'}\n\n"
        except Exception as e:
            yield f"data: {{'status': 'error', 'message': '{str(e)}'}}\n\n"
    
    return Response(generate(), mimetype='text/event-stream')

if __name__ == '__main__':
    app.run()
    
    
