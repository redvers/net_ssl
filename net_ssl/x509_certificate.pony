use "format"
use "collections"

use @X509_new[Pointer[X509] tag]()
use @X509_print[I32](bp: Pointer[_BIO] tag, x: Pointer[X509] tag)
use @PEM_read_bio_X509[Pointer[X509] tag](bio: Pointer[_BIO] tag, x509: Pointer[X509] tag, cb: Pointer[None], u: Pointer[None])
use @X509_get_issuer_name[Pointer[_X509Name] tag](a: Pointer[X509] tag)
use @X509_get_subject_name[Pointer[_X509Name] tag](a: Pointer[X509] tag)
use @X509_digest[U32](data: Pointer[X509] tag, dtype: Pointer[_EVPMD], str: Pointer[U8] tag, len: Pointer[U32] tag)
use @EVP_sha1[Pointer[_EVPMD]]()



primitive _EVPMD

class X509Certificate
  """
  An X509Certificate with all that that entails
  """

  var _cert: Pointer[X509] tag = Pointer[X509]

  new create() =>
    _cert = @X509_new()

  new val _from_cert_ptr(cert: Pointer[X509] tag) =>
    """
    Private method used to create the X509Certificate from an Established SSL
    connection
    """
    _cert = cert

  new val from_pem(data: (Array[U8] val | String val)) ? =>
    """
    A constructor that takes a certificate as PEM data.
    """
    let bio: _BIO = _BIO
    if (not bio.write(data)) then error end
    _cert = @PEM_read_bio_X509(bio.apply(), Pointer[X509], Pointer[None], Pointer[None])
    if (_cert.is_null()) then error end

  fun _ptr(): Pointer[X509] tag =>
    _cert

  fun issuer_name(): String val ? =>
   """
    Returns the issuer's CN.
    """
    _X509Name.string(@X509_get_issuer_name(_cert))?

  fun subject_name(): String val ? =>
    """
    Returns the certificate's CN.
    """
    _X509Name.string(@X509_get_subject_name(_cert))?
/*
  fun not_before_posix(): I64 =>
    """
    Returns the notBefore time for the certificate in UNIX epoch form.
    """
    let notb4: Pointer[ASN1String] tag = @X509_get0_notBefore(_cert)
    ASN1String.time_to_posix(notb4)

  fun not_after_posix(): I64 =>
    """
    Returns the notAfter time for the certificate in UNIX epoch form.
    """
    let notb4: Pointer[ASN1String] tag = @X509_get0_notAfter(_cert)
    ASN1String.time_to_posix(notb4)

  fun get_extensions(): StackX509Extension =>
    """
    Returns an object that represents a collection of Extensions.
    """
    StackX509Extension.create_from_x509(_cert)
*/


  fun print(): String val ? =>
    """
    Returns a textual representation of the certificate in a form which
    is identical to openssl x509 -text.
    """
    let bio: _BIO = _BIO
    if (@X509_print(bio.apply(), _cert) != 1) then error end
    bio.string()
/*
  fun authority_key_id(): String val ? =>
    """
    Returns the Key ID of the Issuing CA Certificate as a string.
    """
    _format_colon_hex(authority_key_id_raw()?)?

  fun authority_key_id_raw(): Array[U8] val ? =>
    """
    Returns the Key ID of the Issuing CA Certificate in its binary form.
    """
    let asn1s: Pointer[ASN1String] tag = @X509_get0_authority_key_id(_cert)
    ASN1String.array(asn1s)?

  fun key_id(): String val ? =>
    """
    Returns the Key ID of the Certificate as a String.
    """
    _format_colon_hex(key_id_raw()?)?

  fun key_id_raw(): Array[U8] val ? =>
    """
    Returns the Key ID of the Certificate in its binary form.
    """
    let asn1s: Pointer[ASN1String] tag = @X509_get0_subject_key_id(_cert)
    ASN1String.array(asn1s)?

  fun serial(): String val ? =>
    """
    Returns the Serial Number of the Certificate in its binary form.
    """
    _format_hex(serial_raw()?)?

  fun serial_raw(): Array[U8] val ? =>
    """
    Returns the Serial Number in its binary form.
    """
    let asn1s: Pointer[ASN1String] tag = @X509_get0_serialNumber(_cert)
    ASN1String.array(asn1s)?

  fun _format_colon_hex(raw: Array[U8] val): String ? =>
    var string: String trn = recover trn String end
    var cnt: USize = 0
    while (cnt < raw.size()) do
      if (cnt > 0) then
        string.append(":")
      end
      string.append(Format.int[U8](raw(cnt)? where width = 2, fmt = FormatHexBare, prec = 2))
      cnt = cnt + 1
    end
    consume string

  fun _format_hex(raw: Array[U8] val): String ? =>
    var string: String trn = recover trn String end
    var cnt: USize = 0
    while (cnt < raw.size()) do
      string.append(Format.int[U8](raw(cnt)? where width = 2, fmt = FormatHexBare, prec = 2))
      cnt = cnt + 1
    end
    consume string
*/
  fun is_null(): Bool => _cert.is_null()

  fun fingerprint(): String val =>
    let size_array: Array[U32] = Array[U32].init(0,1)
    let sha1: Pointer[_EVPMD] = @EVP_sha1()
    let sbuff: Array[U8] ref = recover ref Array[U8].init(0,64) end

    let r: U32 = @X509_digest(_cert, sha1, sbuff.cpointer(), size_array.cpointer())
    var fpr: String trn = recover String end
    try
      for f in Range(0, size_array(0)?.usize()) do
        fpr = fpr + Format.int[U8](sbuff(f)? where width = 2, fmt = FormatHexBare, prec=2)
      end
    end
    consume fpr


  fun get_pem(): String iso^ =>
    let bio: _BIO = _BIO
    bio.write_pem_x509(this)

    let pem: String iso = recover iso
      let certpem: String ref = recover ref String end
      let buffer: Array[U8] ref = recover ref Array[U8].>undefined(1024) end

      while (true) do
        let amount_read: U32 = @BIO_gets(bio.apply(), buffer.cpointer(), U32(1024))
        if (amount_read == 0) then break end
        certpem.concat(buffer.values(), 0, amount_read.usize())
      end
      certpem
    end
    consume pem

